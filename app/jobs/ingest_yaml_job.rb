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
      # ingest_files(resource: resource, files: @yaml[:files])
      # resource.save!
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

    def ingest_files(parent: nil, resource: nil, files: [])
      files.each do |f|
        logger.info "Ingesting file #{f[:path]}"
        file_set = FileSet.new
        file_set.attributes = f[:attributes]
        actor = FileSetActor.new(file_set, @user)
        actor.create_metadata(resource, f[:file_opts])
        actor.create_content(decorated_file(f))
      end
    end
end
