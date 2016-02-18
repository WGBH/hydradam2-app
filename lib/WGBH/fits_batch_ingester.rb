require 'hydra/works'
require 'has_logger'

module WGBH
  class FITSBatchIngester

    include HasLogger

    attr_reader :path, :ingested_objects, :depositor

    def initialize(opts={})
      @path = File.expand_path(opts.delete(:path)) if opts.key?(:path)
      @depositor = opts.delete(:depositor)
      @ingested_objects = []
    end

    def run!
      filenames.each do |filename|
        file_set = FileSet.new
        file_set.apply_depositor_metadata depositor
        file_set.save!
        file = File.open(filename)
        Hydra::Works::AddFileToFileSet.call(file_set, file, :fits)
        file.close
        file_set.assign_properties_from_fits
        @ingested_objects << file_set
      end
    end

    def filenames
      @filenames ||= begin
        files = Dir["#{path}/*"]
        # Exclude files that begin with dot.
        # TODO: exclude more files?
        files.reject! { |filename| filename =~ /^\.\.?/ }
        # Use absolute paths
        files.map! { |filename| File.expand_path(filename) }
      end
    end
  end
end
