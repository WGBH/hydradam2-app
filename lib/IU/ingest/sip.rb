require 'IU/models/file_set'

module IU
  module Ingest
    class SIP

      # This should be WGBH::Models::FileSet, or a descendent thereof.
      FILE_SET_CLASS = IU::Models::FileSet

      attr_reader :path, :depositor, :ingested_objects

      def initialize(opts={})
        raise Error::InvalidPath.new(opts[:path]) unless File.exists?(opts[:path])
        raise ArgumentError, "Missing required option :depositor" unless opts.key? :depositor

        @path = File.expand_path(opts.delete(:path))
        @depositor = opts.delete(:depositor)
        @ingested_objects = []
      end


      def ingest!
        @ingested_objects << create_file_set!(ffprobe: access_copy_ffprobe_path)
        @ingested_objects << create_file_set!(ffprobe: mezzanine_copy_ffprobe_path)
      end

      private

      def filenames
        Dir.entries(path).reject { |entry| ['.', '..'].include? entry }.map{ |filename| File.expand_path(filename, path) }
      end

      def access_copy_ffprobe_path
        filenames.select { |filename| filename =~ /_access_ffprobe\.xml$/}.first
      end

      def mezzanine_copy_ffprobe_path
        filenames.select { |filename| filename =~ /_mezz_ffprobe\.xml$/}.first
      end

      def create_file_set!(opts={})

        raise ArgumentError, "Invalid ffprobe file '#{opts[:ffprobe]}'" unless File.exists?(opts[:ffprobe])

        file_set = FILE_SET_CLASS.new
        file_set.apply_depositor_metadata depositor
        file_set.save!
        ffprobe_file = File.open(opts[:ffprobe])
        Hydra::Works::AddFileToFileSet.call(file_set, ffprobe_file, :ffprobe)
        file_set.assign_properties_from_ffprobe
        file_set.save!
        file_set
      end

    end


    module Error
      class InvalidPath < StandardError
        def initialize(invalid_path)
          super("Invalid SIP path '#{invalid_path}'")
        end
      end
    end
  end
end
  
#   class SIPIngester

#     attr_reader :path, :depositor, :ingested_objects, :access_copy_file_set
#                 :mezzanine_file_set
    
#     def initialize(opts={})
#       raise ArgumentError, "Missing required option :path" unless opts.key? :path
#       raise ArgumentError, "Missing required option :depositor" unless opts.key? :depositor

#       @path = File.expand_path(opts.delete(:path))
#       @depositor = opts.delete(:depositor)
#       @ingested_objects = []
#     end

#     def run!
#       @ingested_objects << ffprobe_file_set
#     end

#     def access_copy_ffprobe_path
#       filenames.select { |f| f =~ /access_ffprobe.xml/ }.first
#     end

#     def mezzanine_ffprobe_path

#       require 'pry'
#       binding.pry

#       filenames.select { |f| f =~ /mezz_ffprobe.xml$/ }.first
#     end

#     def access_copy_file_set!
#       @access_copy_file_set ||= begin
#         file_set = FileSet.new()
#         file_set.apply_depositor_metadata depositor
#         file_set.save!
#         file = File.open(access_copy_ffprobe_path)
#         Hydra::Works::AddFileToFileSet.call(file_set, file, :ffprobe)
#         file.close
#         file_set.assign_properties_from_ffprobe
#         file_set.save!
#       end
#     end

#     def mezzanine_file_set!
#       @mezzanine_file_set ||= begin
#         file_set = FileSet.new()
#         file_set.apply_depositor_metadata depositor
#         file_set.save!
#         file = File.open(mezzanine_ffprobe_path)
#         Hydra::Works::AddFileToFileSet.call(file_set, file, :ffprobe)
#         file.close
#         file_set.assign_properties_from_ffprobe
#         file_set.save!
#       end
#     end

#     def filenames
#       @filenames = begin
#         files = Dir["#{path}/*"]
#         files.map! {|filename| File.expand_path(filename)}
#       end
#     end
#   end
# end
