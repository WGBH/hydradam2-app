require 'pry'

module IU
  module Ingest
    class SIP
      attr_reader :tarball, :depositor

      def initialize(opts={})
        validate_options! opts
        @depositor = opts[:depositor]
        @tarball = File.expand_path(opts[:tarball])
      end


      # Establish relationships between all the objects created from SIP files
      # extracted form the tarball.
      def ingest!
        work.mdpi_xml = mdpi_xml
        work.title << mdpi_title
        work.members << access_copy
        work.members << mezzanine_copy
        work.save!
        delete_extracted_files!
      end


      # Returns the FileSet object representing the access copy.
      def access_copy
        @access_copy ||= create_file_set!(ffprobe: access_copy_ffprobe_path, quality_level: :access)
      end

      # Returns the FileSet object representing the mezzanine copy.
      def mezzanine_copy
        @mezzanine_copy ||= create_file_set!(ffprobe: mezzanine_copy_ffprobe_path, quality_level: :mezzanine)
      end

      # Returns an XMLFile object containing the MDPI xml.
      def mdpi_xml
        @mdpi_xml_file ||= begin
          XMLFile.new.tap do |xml_file|
            xml_file.content = File.read(mdpi_xml_path)  
          end
        end
      end

      def mdpi_title
        @mdpi_title ||= begin
          noko = mdpi_xml.noko.dup
          noko.remove_namespaces!
          noko.xpath('/IU/Carrier/Barcode').text
        end
      end

      # Returns the Work object
      def work
        @work ||= Work.new.tap do |work|
          work.apply_depositor_metadata depositor
        end
      end

      private

      # Validates options passed to the constructor
      def validate_options!(opts)
        raise MissingRequiredOption.new(:tarball) unless opts.key? :tarball
        raise MissingRequiredOption.new(:depositor) unless opts.key? :depositor

        raise InvalidTarball.new(opts[:tarball]) unless File.exists? opts[:tarball]
      end

      # Unpacks the tarball if needed, and returns the root directory for the
      # SIP
      def root_dir
        @root_dir ||= begin
          root_dir_parent = File.dirname(tarball)
          Archive::Tar::Minitar.unpack(tarball, root_dir_parent)
          root_dir_basename = tarball_entries.select{ |tar_entry| tar_entry.directory? }.first.name
          File.expand_path(root_dir_basename, root_dir_parent)
        end

        raise ExtractionError unless File.directory?(@root_dir)
        @root_dir
      end

      # Returns an array of Archive::Tar::Minitar::Reader::EntryStream objects.
      # See http://rubyworks.github.io/path/Archive/Tar/Minitar/Reader/EntryStream.html
      def tarball_entries
        @tarball_entries ||= begin
          File.open(tarball, 'rb') do |file|
            Archive::Tar::Minitar.open(file).map{ |entry| entry }.to_a
          end
        end
      end

      def filenames
        Dir["#{root_dir}/*"]
      end

      def access_copy_ffprobe_path
        filenames.select { |filename| filename =~ /_access_ffprobe\.xml$/}.first
      end

      def mezzanine_copy_ffprobe_path
        filenames.select { |filename| filename =~ /_mezz_ffprobe\.xml$/}.first
      end

      def mdpi_xml_path
        filenames.select { |filename| filename =~ /MDPI_\d+\.xml/ }.first
      end

      def create_file_set!(opts={})
        raise ArgumentError, "Invalid ffprobe file '#{opts[:ffprobe]}'" unless File.exists?(opts[:ffprobe])

        FileSet.new.tap do |file_set|
          file_set.apply_depositor_metadata depositor
          file_set.quality_level = opts[:quality_level]
          file_set.save!
          File.open(opts[:ffprobe]) do |ffprobe_file|
            Hydra::Works::AddFileToFileSet.call(file_set, ffprobe_file, :ffprobe)
          end
          file_set.assign_properties_from_ffprobe
          file_set.save!
        end
      end

      def delete_extracted_files!
        FileUtils.remove_entry_secure(root_dir)
      end
    end


    class InvalidTarball < StandardError
      def initialize(tarball)
        super("Invalid tarball '#{tarball}'")
      end
    end

    class MissingRequireOption < StandardError
      def initialize(opt)
        super("Missing required option :#{opt}")
      end
    end
  end
end
