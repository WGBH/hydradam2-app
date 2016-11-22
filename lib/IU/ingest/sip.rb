require 'pry'

module IU
  module Ingest
    class FileReader
      def initialize(filename)
        @filename = filename
        @reader = reader_class.new(filename, File.read(filename))
      end
      attr_reader :filename, :reader

      delegate :id, :attributes, to: :reader

      def reader_class
        case @filename
        when /pod\.xml$/
          PodReader
        when /mods\.xml$/
          ModsReader
        when /4\d{3}\.xml$/
          BarcodeReader
        else
          NullReader # raise exception?
        end
      end

      def type
        { PodReader => :pod,
          ModsReader => :mods,
          BarcodeReader => :mdpi
        }[reader_class]
      end
    end
    class NullReader
      def initialize(id, source)
        @id = id
        @source = source
      end
      attr_reader :id, :source
      
      def attributes
        {}
      end
    end
    class XmlReader
      def initialize(id, source)
        @id = id
        @source = source
        @xml = Nokogiri::XML(source).remove_namespaces!
        parse
      end
      attr_reader :id, :source, :xml

      def parse
      end

      def attributes
        begin
          att_lookups = self.class.const_get(:ATT_LOOKUPS)
        rescue
          att_lookups = {}
        end
        att_lookups.inject({}) do |h, (k,v)|
          h[k] = xml.xpath(v).map(&:text)
          h
        end
      end
    end
    class PodReader < XmlReader
      ATT_LOOKUPS = {
        mdpi_barcode: '//details/mdpi_barcode',
        unit_of_origin: '//assignment/unit'
      }
      def attributes
        result = super
        result[:mdpi_barcode] = result[:mdpi_barcode].first
        result
      end
    end
    class ModsReader < XmlReader
      ATT_LOOKUPS = {
        title: '/mods/titleInfo/title'
      }
    end
    class BarcodeReader < XmlReader
      ATT_LOOKUPS = {
        mdpi_date: '/IU/Carrier/Parts/Part/Ingest/Date'
      }
      def attributes
        result = super
        result[:mdpi_date] = DateTime.parse(result[:mdpi_date].first)
        result
      end
    end
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
        work.save!
        access_copy.save!
        production_copy.save!

        begin
          preservation_copy.save!
        rescue MissingTarball => e
          nil # Preservation copy is not required.
        end

        work.save!

        fix_blank_title! work.access_copy # Access ffprobe does not contain title

        delete_extracted_files!
      end


      # Returns the FileSet object representing the access copy.
      def access_copy
        @access_copy ||= create_file_set!(parent: work,
                                          ffprobe: access_copy_ffprobe_path,
                                          quality_level: :access)
      end

      # Returns the FileSet object representing the production copy.
      def production_copy
        @production_copy ||= create_file_set!(parent: work,
                                              ffprobe: production_copy_ffprobe_path,
                                              quality_level: :production)
      end

      
      # Returns FileSet object representing the pres copy.
      def preservation_copy
        @preservation_copy ||= create_file_set!(parent: work,
                                                ffprobe: preservation_copy_ffprobe_path,
                                                quality_level: :preservation)
      end

      # Returns the Work object
      def work
        @work ||= Work.new.tap do |work|
          work.apply_depositor_metadata depositor
          work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC

          work.mdpi_xml.content = File.read(mdpi_xml_path)
          work.assign_properties_from_mdpi_xml

          work.mods_xml.content = File.read(mods_xml_path)
          work.assign_properties_from_mods_xml

          work.pod_xml.content = File.read(pod_xml_path)
          work.assign_properties_from_pod_xml
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

      def mods_xml_path
        filenames.select { |filename| filename =~ /MDPI_\d+_mods\.xml/ }.first
      end

      def pod_xml_path
        filenames.select { |filename| filename =~ /MDPI_\d+_pod\.xml/ }.first
      end

      def create_file_set!(opts={})
        raise MissingTarball, "Missing ffprobe file '#{opts[:ffprobe]}'" unless File.exists?(opts[:ffprobe].to_s)
        parent = opts[:parent]
        FileSet.new.tap do |file_set|
          file_set.apply_depositor_metadata depositor
          file_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          parent.ordered_members << file_set
          parent.save!
          file_set.quality_level = opts[:quality_level]
          file_set.save!
          File.open(opts[:ffprobe]) do |f|
            Hydra::Works::AddFileToFileSet.call(file_set, f, :ffprobe)
          end
          file_set.assign_properties_from_mods
          file_set.assign_properties_from_mdpi
          file_set.assign_properties_from_pod
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

      # Sets a FileSet's blank title to its parent's title.
      def fix_blank_title!(obj)
        obj.title = obj.parent.title if obj.title.blank? || obj.title == ['']
        obj.save!
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
