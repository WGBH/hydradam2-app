require 'hydra/works'
require 'has_logger'
require 'WGBH/ingest/sip'

module WGBH
  module Ingest
    class FITSBatch

      include HasLogger

      attr_reader :path, :sips, :depositor

      def initialize(opts={})
        @path = File.expand_path(opts.delete(:path)) if opts.key?(:path)
        @depositor = opts.delete(:depositor)
        @sips = []
      end

      def ingest!
        filenames.each do |filename|
          sip = WGBH::Ingest::SIP.new depositor: depositor
          # append to the @sips to allow inspecting after ingest.
          @sips << sip
          sip.fits_path = filename
          sip.ingest!
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
end
