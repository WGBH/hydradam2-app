class PreingestJob < ActiveJob::Base
  queue_as :preingest

  def perform(package_class, preingest_file, user)
    logger.info "Preingesting #{package_class} #{preingest_file}"
    @preingest_file = preingest_file
    @package_reader = package_class.new(preingest_file)
    @user = user

    preingest
  end

  private

    def preingest
      @yaml_hash = {}
      @yaml_hash[:resource] = @package_reader.resource_class.to_s
      @yaml_hash[:work_attributes] = @package_reader.work_attributes
      @yaml_hash[:file_set_attributes] = @package_reader.file_set_attributes
      @yaml_hash[:source_metadata] = @package_reader.source_metadata
      @yaml_hash[:file_sets] = @package_reader.file_sets
      @yaml_hash[:sources] = @package_reader.sources

      output_file = @preingest_file.gsub(/\..{3,4}/, '.yml')
      File.write(output_file, @yaml_hash.to_yaml)
      logger.info "Created YAML file #{output_file}"
    end
end
