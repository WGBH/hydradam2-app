class PreingestJob < ActiveJob::Base
  queue_as :preingest

  def perform(preingest_file, user)
    logger.info "Preingesting #{preingest_file}"
    @preingest_file = preingest_file
    @user = user

    preingest
  end

  private

    def preingest
      yaml_hash = {}
      yaml_hash[:resource] = Work.to_s
      yaml_hash[:attributes] = {}
      yaml_hash[:source_metadata] = nil
      yaml_hash[:files] = []
      yaml_hash[:sources] = []

      output_file = @preingest_file.gsub(/\..{3,4}/, '.yml')
      File.write(output_file, yaml_hash.to_yaml)
      logger.info "Created YAML file #{output_file}"
    end
end
