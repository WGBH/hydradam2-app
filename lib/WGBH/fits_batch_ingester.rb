require 'rails_helper'
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
        @ingested_objects << file_set
      end
    end

    private

    def filenames
      filenames = Dir["#{path}/*"]
      # Exclude files that begin with dot.
      # TODO: exclude more files?
      filenames.reject! { |filename| filename =~ /^\.\.?/ }
      # Use absolute paths
      filenames.map! { |filename| File.expand_path(filename) }
    end
  end
end
