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
      @yaml_hash = {}
      @yaml_hash[:resource] = Work.to_s
      @yaml_hash[:attributes] = {}
      @yaml_hash[:source_metadata] = nil
      @yaml_hash[:files] = []
      @yaml_hash[:sources] = []

      filenames.each { |filename| process_file(filename) }
      delete_extracted_files!

      output_file = @preingest_file.gsub(/\..{3,4}/, '.yml')
      File.write(output_file, @yaml_hash.to_yaml)
      logger.info "Created YAML file #{output_file}"
    end

    def tarball_entries
      @tarball_entries ||= begin
        File.open(@preingest_file, 'rb') do |file|
          Archive::Tar::Minitar.open(file).map{ |entry| entry }.to_a
        end
      end
    end

    def filenames
      @filenames ||= Dir["#{root_dir}/*"]
    end

    def root_dir
      @root_dir ||= begin
        root_dir_parent = File.dirname(@preingest_file)
        Archive::Tar::Minitar.unpack(@preingest_file, root_dir_parent)
        root_dir_basename = tarball_entries.select{ |tar_entry| tar_entry.directory? }.first.name
        File.expand_path(root_dir_basename, root_dir_parent)
      end

      raise ExtractionError unless File.directory?(@root_dir)
      @root_dir
    end

    def delete_extracted_files!
      FileUtils.remove_entry_secure(root_dir)
    end

    def process_file(filename)
      file_hash = {}
      file_hash[:filename] = filename
      @yaml_hash[:files] << file_hash 

      file_reader = IU::Ingest::FileReader.new(filename)
      unless file_reader&.type.nil?
        # FIXME: missing required Model RDF mappings for AttributeIngester
        ai = IU::Ingest::AttributeIngester.new(file_reader.id, file_reader.attributes)
        @yaml_hash[:attributes][file_reader.type] = ai.raw_attributes
        # @yaml_hash[:attributes][file_reader.type] = file_reader.attributes
      end
    end
end
