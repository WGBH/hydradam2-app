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
      @yaml_hash[:work_attributes] = {}
      @yaml_hash[:file_set_attributes] = {}
      @yaml_hash[:source_metadata] = nil
      @yaml_hash[:files] = []
      @yaml_hash[:sources] = []

      filenames.each { |filename| process_file(filename) }
      postprocess
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
      file_hash = { filename: filename.sub(/.*\//, '') }
      file_reader = IU::Ingest::FileReader.new(filename)
      unless file_reader&.type.nil?
        work_ai = IU::Ingest::AttributeIngester.new(file_reader.id, file_reader.attributes, factory: @yaml_hash[:resource].constantize)
        file_set_ai = IU::Ingest::AttributeIngester.new(file_reader.id, file_reader.file_attributes, factory: FileSet)
        if file_reader.type.in? [:pod, :mods, :mdpi]
          @yaml_hash[:work_attributes][file_reader.type] = work_ai.raw_attributes
          @yaml_hash[:file_set_attributes][file_reader.type] = file_set_ai.raw_attributes
        elsif file_reader.type.in? [:purl, :md5]
          @purls_map = file_reader.reader.purls_map if file_reader.type == :purl
          @md5sums_map = file_reader.reader.md5sums_map if file_reader.type == :md5
        else
          file_hash.merge!(file_reader.file_properties)
          file_hash[:attributes] = file_set_ai.raw_attributes
        end
      end
      @yaml_hash[:files] << file_hash 
    end

    def md5sums_map
      @md5sums_map ||= {}
    end

    def purls_map
      @purls_map ||= {}
    end

    def postprocess
      @yaml_hash[:files].each do |file_hash|
        if filename = file_hash[:filename]
          file_hash[:md5sum] = md5sums_map[filename] if md5sums_map[filename]
          file_hash[:purl] = purls_map[filename] if purls_map[filename]
        end
      end
    end
end
