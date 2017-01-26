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
        logger.info "Ingesting FileSet for #{f[:filename]}"
        file_set = FileSet.new
        file_set.attributes = f[:attributes]
        file_set.apply_depositor_metadata(@user)
        file_set.save!
        actor = FileSetActor.new(file_set, @user)
        ingest_files(resource, file_set, actor, f[:files]) if f[:files].present?
        ingest_events(file_set, f[:events]) if f[:events].present?
        add_ingestion_event(file_set)
      end
    end

    def decorated_file(f)
      IoDecorator.new(open(f[:path]), f[:mime_type], File.basename(f[:path]))
    end

    def ingest_files(resource, file_set, actor, files)
      files.each_with_index do |file, i|
        logger.info "FileSet #{file_set.id}: ingesting file: #{file[:filename]}"
        actor.create_metadata(resource, file[:file_opts]) if i.zero? && file[:path]
        actor.create_content(decorated_file(file), file[:use]) if file[:path] #FIXME: handle purl case
      end
    end
    def ingest_events(file_set, events)
      events.each do |event|
        logger.info "FileSet #{file_set.id}: adding event: #{event[:attributes][:premis_event_type]&.join(', ')}"
        add_event(file_set, event[:attributes])
      end
    end

    def add_event(file_set, event_attributes, prep_attributes: true)
      e = Preservation::Event.new
      e.premis_event_related_object = file_set
      if prep_attributes
        event_attributes[:premis_event_type] = event_attributes[:premis_event_type].map do |pet|
          Preservation::PremisEventType.new(pet).uri
        end
        event_attributes[:premis_agent] = event_attributes[:premis_agent].map do |agent|
          ::RDF::URI.new(agent)
        end
      end
      e.attributes = event_attributes
      e.save!
    end
      
    def add_ingestion_event(file_set)
      event = {}
      event[:attributes] = {
        premis_event_type: ['ing'],
        premis_agent: ['mailto:' + @user.email],
        premis_event_outcome: ['SUCCESS'],
        premis_event_date_time: [DateTime.now]
      }
      ingest_events(file_set, [event])
    end

end
