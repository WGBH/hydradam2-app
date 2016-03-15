module IU
  
  class SIPIngester

<<<<<<< HEAD
    attr_reader :path, :depositor, :ingested_objects, :access_copy_file_set
                :mezzanine_file_set
=======
    attr_reader :path, :depositor, :ingested_objects
>>>>>>> Adds parameter checking
    
    def initialize(opts={})
      raise ArgumentError, "Missing required option :path" unless opts.key? :path
      raise ArgumentError, "Missing required option :depositor" unless opts.key? :depositor

<<<<<<< HEAD
      @path = File.expand_path(opts.delete(:path))
=======
      @path = File.expand_path(:path) if opts.key?(:path)
>>>>>>> Adds parameter checking
      @depositor = opts.delete(:depositor)
      @ingested_objects = []
    end

    def run!
      @ingested_objects << ffprobe_file_set
    end

    def access_copy_ffprobe_path
      filenames.select { |f| f =~ /access_ffprobe.xml/ }.first
    end

    def mezzanine_ffprobe_path
      filenames.select { |f| f =~ /mezz_ffprobe.xml$/ }.first
    end

    def access_copy_file_set!
      @access_copy_file_set ||= begin
        file_set = FileSet.new()
        file_set.apply_depositor_metadata depositor
        file_set.save!
        file = File.open(access_copy_ffprobe_path)
        Hydra::Works::AddFileToFileSet.call(file_set, file, :ffprobe)
        file.close
        file_set.assign_properties_from_ffprobe
        file_set.save!
      end
    end

    def mezzanine_file_set!
      @mezzanine_file_set ||= begin
        file_set = FileSet.new()
        file_set.apply_depositor_metadata depositor
        file_set.save!
        file = File.open(mezzanine_ffprobe_path)
        Hydra::Works::AddFileToFileSet.call(file_set, file, :ffprobe)
        file.close
        file_set.assign_properties_from_ffprobe
        file_set.save!
      end
    end

    def filenames
      @filenames = begin
        files = Dir["#{path}/*"]
        files.map! {|filename| File.expand_path(filename)}
      end
    end
  end
end
