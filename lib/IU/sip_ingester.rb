module IU
  
  class SIPIngester

    attr_accessor :path
    attr_reader :ingested_objects, :depositor
    
    def initialize(opts={})

	@path = File.expand_path(:path) if opts.key?(:path)
	@depositor = opts.delete(:depositor)
	@ingested_objects = []
	
    end

    def run!
      
      @ingested_objects << ffprobe_file_set
       
    end

    def ffprobe_path

      filenames.select { |f| f =~ /.*ffprobe.*/ }.first

    end

    def filenames
      
       require 'pry'
       binding.pry
	
      @filenames = begin
        files = Dir["#{path}/*"]
       #files.reject! {|filename| filename =~ /^\.\.?$/}
        files.map! {|filename| File.expand_path(filename)}
      end
    end

    def ffprobe_file_set

      @ffprobe_file_set ||= begin
        file_set = FileSet.new()
        file_set.apply_depositor_metadata depositor
        file_set.save!
        file = File.open(ffprobe_path)
        Hydra::Works::AddFileToFilSet.call(file_set, file, :ffprobe)
        file.close
        file_set.assign_properties_from_ffprobe
        file_set.save!
      end
	
    end

  end

end
