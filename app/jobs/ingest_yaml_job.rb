class IngestYAMLJob < ActiveJob::Base
  queue_as :ingest

  # @param [String] yaml_file Filename of a YAML file to ingest
  # @param [String] user User to ingest as
  def perform(yaml_file, user)
    logger.info "Ingesting YAML #{yaml_file}"
    @yaml_file = yaml_file
    @yaml = File.open(yaml_file) { |f| Psych.load(f) }
    @user = user
    ingest
  end

  private

    def ingest
      resource = @yaml[:resource].constantize.new
      if @yaml[:work_attributes].present?
        @yaml[:work_attributes].each { |_set_name, attributes| resource.attributes = attributes }
      end
      resource.source_metadata = @yaml[:source_metadata] if @yaml[:source_metadata].present?
      resource.apply_depositor_metadata @user
      resource.save!
      logger.info "Created #{resource.class}: #{resource.id}"

      # attach_sources resource
      ingest_file_sets(resource: resource, files: @yaml[:file_sets])
      resource.save!
    end

    def attach_sources(resource)
      return unless @yaml[:sources].present?
      @yaml[:sources].each do |source|
        attach_source(resource, source[:title], source[:file])
      end
    end

    def attach_source(resource, title, file)
      file_set = FileSet.new
      file_set.title = title
      actor = FileSetActor.new(file_set, @user)
      actor.attach_related_object(resource)
      actor.attach_content(File.open(file, 'r:UTF-8'))
    end

    def ingest_file_sets(parent: nil, resource: nil, files: [])
      files.select { |f| f[:attributes].present? }.each do |f|
        logger.info "Ingesting file #{f[:path]}"
        file_set = FileSet.new
        file_set.attributes = f[:attributes]
        actor = FileSetActor.new(file_set, @user)
        # FIXME: handle all files, not just first, and set proper relations (not just original_file)
        if f[:files].any?
          file = f[:files].first
          actor.create_metadata(resource, file[:file_opts])
          actor.create_content(decorated_file(file))
        end
        if f[:events].present? 
          f[:events].each do |event|
            e = Preservation::Event.new
            event[:attributes][:premis_event_type] = event[:attributes][:premis_event_type].map do |pet|
              Preservation::PremisEventType.new(pet).uri
            end
            event[:attributes][:premis_agent] = event[:attributes][:premis_agent].map do |agent|
              ::RDF::URI.new(agent)
            end
            e.attributes = event[:attributes]
            e.premis_event_related_object = file_set
            e.save!
          end
        end
        add_ingestion_event(file_set)
      end
    end

    def decorated_file(f)
      IoDecorator.new(open(f[:path]), f[:mime_type], File.basename(f[:path]))
    end

    def add_ingestion_event(file_set)
      e = Preservation::Event.new
      e.premis_event_related_object = file_set
      e.premis_event_type = Array.wrap(Preservation::PremisEventType.new(pet).uri)
      e.premis_agent = Array.wrap(::RDF::URI.new(agent))
      # e.premis_event_outcome = 'SUCCESS'
      e.premis_event_date_time = Array.wrap(DateTime.now)
      e.save!
    end

end
