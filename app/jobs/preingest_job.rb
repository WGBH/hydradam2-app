class PreingestJob < ActiveJob::Base
  queue_as :preingest

  def perform(document_class, preingest_file, user)
    logger.info "Preingesting #{document_class} #{preingest_file}"
    @document = document_class.new preingest_file
    @user = user

    preingest
  end

  private

    def preingest
      yaml_hash = {}
      yaml_hash[:resource] = @document.resource_class.to_s
      yaml_hash[:attributes] = @document.attributes
      yaml_hash[:source_metadata] = @document.source_metadata
      
      if @document.multi_volume?
        yaml_hash[:volumes] = @document.volumes
      else
        yaml_hash[:structure] = @document.structure
        yaml_hash[:files] = @document.files
      end

      yaml_hash[:sources] = [{ title: @document.source_title, file: @document.source_file }]

      File.write(@document.yaml_file, yaml_hash.to_yaml)
      logger.info "Created YAML file #{File.basename(@document.yaml_file)}"
    end
end
