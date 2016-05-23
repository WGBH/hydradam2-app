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
        work.ordered_members << access_copy
        work.ordered_members << production_copy

        begin
          work.ordered_members << preservation_copy
        rescue MissingTarball => e
          nil # Preservation copy is not required.
        end

        work.save!
        delete_extracted_files!
      end


      # Returns the FileSet object representing the access copy.
      def access_copy
        @access_copy ||= create_file_set!(ffprobe: access_copy_ffprobe_path, quality_level: :access)
      end

      # Returns the FileSet object representing the production copy.
      def production_copy
        @production_copy ||= create_file_set!(ffprobe: production_copy_ffprobe_path, quality_level: :production)
      end

      
      # Returns FileSet object representing the pres copy.
      def preservation_copy
        @preservation_copy ||= create_file_set!(ffprobe: preservation_copy_ffprobe_path, quality_level: :preservation)
      end

      # Returns the Work object
      def work
        @work ||= Work.new.tap do |work|
          work.apply_depositor_metadata depositor
          work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          work.mdpi_xml.content = File.read(mdpi_xml_path)
          work.assign_properties_from_mdpi_xml
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

      def production_copy_ffprobe_path
        filenames.select { |filename| filename =~ /_(mezz|prod)_ffprobe\.xml$/}.first
      end
      
      def preservation_copy_ffprobe_path
        filenames.select { |filename| filename =~ /_pres_ffprobe\.xml$/}.first
      end

      def mdpi_xml_path
        filenames.select { |filename| filename =~ /MDPI_\d+\.xml/ }.first
      end

      def create_file_set!(opts={})
        raise MissingTarball, "Missing ffprobe file '#{opts[:ffprobe]}'" unless File.exists?(opts[:ffprobe].to_s)
        FileSet.new.tap do |file_set|
          file_set.apply_depositor_metadata depositor
          file_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          file_set.quality_level = opts[:quality_level]
          file_set.save!
          File.open(opts[:ffprobe]) do |ffprobe_file|
            Hydra::Works::AddFileToFileSet.call(file_set, ffprobe_file, :ffprobe)
          end
          file_set.assign_properties_from_ffprobe
          file_set.original_checksum += [md5_for(file_set.filename)]
          file_set.save!
        end
      end

      def delete_extracted_files!
        FileUtils.remove_entry_secure(root_dir)
      end

      def md5_for(filename)
        # The filename and the relative filepath from the manifest will not be the same.
        # But comparing their basenames should be good enough.
        # The .first.try(:last) returns the selected md5, or nil if not found.
        md5_checksums.select { |filepath, md5| File.basename(filepath) == File.basename(filename) }.first.try(:last)
      end

      # Returns a hash of md5 md5_checksums, keyed by file path, from the md5
      # manifest file.
      def md5_checksums
        @md5_checksums ||= begin
          # Parses the md5 manifest into an array of 2-element
          # arrays, where the first element is the md5, and the 2nd element is
          # the file path.
          entries = File.readlines(md5_manifest_path).map(&:chomp).map{ |entry| entry.split(/\s+/) }
          md5_values = entries.map(&:first)
          file_paths = entries.map(&:last)
          Hash[file_paths.zip(md5_values)]
        end
      end

      # Returns the path to the md5 manfiest file.
      def md5_manifest_path
        filenames.select { |filename| File.basename(filename) == 'manifest-md5.txt' }.first
      end
    end


    class InvalidTarball < StandardError
      def initialize(tarball)
        super("Invalid tarball '#{tarball}'")
      end
    end

    class MissingRequiredOption < StandardError
      def initialize(opt)
        super("Missing required option :#{opt}")
      end
    end

    class MissingTarball < ArgumentError
    end

  end
end
