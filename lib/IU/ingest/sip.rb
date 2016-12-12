require 'pry'

module IU
  module Ingest
    class FileReader
      def initialize(filename)
        @filename = filename
        @reader = reader_class.new(filename, File.read(filename))
      end
      attr_reader :filename, :reader

      delegate :id, :attributes, :file_attributes, :file_properties, to: :reader

      def reader_class
        case @filename
        when /pod\.xml$/
          PodReader
        when /mods\.xml$/
          ModsReader
        when /4\d{3}\.xml$/
          BarcodeReader
        when /ffprobe\.xml$/
          FFprobeReader
        else
          NullReader # raise exception?
        end
      end

      def type
        { PodReader => :pod,
          ModsReader => :mods,
          BarcodeReader => :mdpi,
          FFprobeReader => :ffprobe
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

      def get_attributes_set(atts_const)
        begin
          att_lookups = self.class.const_get(atts_const)
        rescue
          return {}
        end
        att_lookups.inject({}) do |h, (k,v)|
          h[k] = xml.xpath(v).map(&:text)
          h
        end
      end

      # for Work metadata
      def attributes
        get_attributes_set(:WORK_ATT_LOOKUPS)
      end

      # for fileset metadata run through AttributeIngester
      def file_attributes
        get_attributes_set(:FILE_ATT_LOOKUPS)
      end

      # for file properties, outside normal metadata handled specially in ingest
      def file_properties
        { mime_type: 'application/xml',
          path: id,
          file_opts: {},
        }
      end
    end
    class PodReader < XmlReader
      WORK_ATT_LOOKUPS = {
        mdpi_barcode: '//details/mdpi_barcode',
        unit_of_origin: '//assignment/unit',
        original_format: '//technical_metadata/format',
        recording_standard: '//technical_metadata/recording_standard',
        tape_stock_brand: 'tape_stock_brand',
        image_format: '//technical_metadata/image_format'
      }
      FILE_ATT_LOOKUPS = {
        unit_of_origin: '//assignment/unit',
        identifier: '//details/mdpi_barcode'
      }
      def attributes
        result = super
        result[:mdpi_barcode] = result[:mdpi_barcode].first
        result
      end
    end
    class ModsReader < XmlReader
      WORK_ATT_LOOKUPS = {
        title: '/mods/titleInfo/title'
      }
      FILE_ATT_LOOKUPS = {} # No FileSet attributes from Mods
    end
    class BarcodeReader < XmlReader
      WORK_ATT_LOOKUPS = {
        mdpi_date: '/IU/Carrier/Parts/Part/Ingest/Date',
        part: '/IU/Carrier/Parts/Part/@Side',
        digitized_by_entity: '/IU/Carrier/Parts/DigitizingEntity',
        digitized_by_staff: '/IU/Carrier/Parts/Part/Ingest/Created_by',
        extraction_workstation: '/IU/Carrier/Parts/Part/Ingest/Extraction_workstation/Manufacturer',
        tape_playback_calibration_used: 'tape_playback_calibration_used',
        digitization_comments: '//Comments',
        original_identifier: '/IU/Carrier/Identifier',
        definition: '/IU/Carrier/Definition',
        original_media_damage: 'PhysicalCondition/Damage',
        original_media_preservation_problem: 'PhysicalCondition/PreservationProblem',
        qc_status: 'QCStatus',
        manual_qc_check: 'ManualCheck',
        encoder_manufacturer: 'Encoder/Manufacturer',
        ad_manufacturer: 'AdDevices/Manufacturer',
        speed_used: 'Speed_used',
        tbc_manufacturer: 'TbcDevices/Manufacturer',
        tape_thickness: 'Thickness',
      }
      FILE_ATT_LOOKUPS = {
        part: '/IU/Carrier/Parts/Part/@Side',
        date_generated: '/IU/Carrier/Parts/Part/Ingest/Date'
      }
      def attributes
        result = super
        result[:mdpi_date] = DateTime.parse(result[:mdpi_date].first)
        result[:total_parts] = xml.xpath('count(//Part)').to_i
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

    class AttributeIngester
      def initialize(source_id, source_attributes, factory: Work, context: CONTEXT)
        # FIXME: do this right
        @source_id = 'file://' + source_id
        @source_attributes = source_attributes
        @factory = factory
        @context = context
      end
      attr_reader :source_id, :source_attributes, :factory, :context
  
      # Runs full transformation pipeline:
      #
      # * assigns outbound_graph to proxy_record
      # * filters proxy_record attributes down to those acquired from outbound_graph
      # * sets attribute values as RDF::Literal for single values, ActiveTriples::Relation for multiple
      # * (ActiveTriple relations may have non-deterministic order)
      #
      # @return [Hash] RDF attributes for the target factory object
      def attributes
        @attributes ||=
          begin
            Hash[
              cleaned_attributes.map do |k, _|
                if k.in? singular_fields
                  [k, proxy_record.get_values(k, literal: true).first]
                else
                  [k, proxy_record.get_values(k, literal: true)]
                end
              end
            ]
          end
      end
  
      # Runs abbreviated transformation pipeline:
      #
      # * checks outbound_statements against factory predicates
      # * sets attribute values simple values for single values, Array for multiple
      # * (Array values should have a deterministic order)
      #
      # @return [Hash] Array, raw-valued attributes for target factory object
      def raw_attributes
        @raw_attributes ||=
          begin
            raw_hash = {}
            outbound_statements.each do |s|
              target_property = outbound_predicates_to_properties[s.predicate]
              next if target_property.nil?
              if target_property.in? singular_fields
                raw_hash[target_property] = s.object.value
              else
                raw_hash[target_property] ||= []
                raw_hash[target_property] << s.object.value
              end
            end
            raw_hash
          end
      end
  
      private
  
        CONTEXT = YAML.load(File.read(Rails.root.join('config/context.yml')))
  
        # used by both pipelines
        def outbound_statements
          @outbound_statements ||=
            begin
              jsonld_hash = {}
              jsonld_hash['@context'] = context["@context"]
              jsonld_hash['@id'] = source_id
              jsonld_hash.merge!(source_attributes.stringify_keys)
              JSON::LD::API.toRdf(jsonld_hash)
            end
        end
  
        # used by full pipeline, only
        def outbound_graph
          @outbound_graph ||= RDF::Graph.new << outbound_statements
        end
  
        # used by full pipeline, only
        def proxy_record
          @proxy_record ||= factory.new.tap do |resource|
            outbound_graph.each do |statement|
              resource.resource << RDF::Statement.new(resource.rdf_subject, statement.predicate, statement.object)
            end
          end
        end
  
        # used by full pipeline, only
        def appropriate_fields
          outbound_predicates = outbound_graph.predicates.to_a
          result = proxy_record.class.properties.select do |_key, value|
            outbound_predicates.include?(value.predicate)
          end
          result.keys
        end
  
        # used by both pipelines
        def singular_fields
          @singular_fields ||= factory.properties.select { |_att, config| config[:multiple] == false }.keys + ['visibility']
        end
  
        # used by full pipeline, only
        def cleaned_attributes
          proxy_record.attributes.select do |k, _v|
            appropriate_fields.include?(k)
          end
        end
  
        VISIBILITY = RDF::URI.new('http://library.princeton.edu/terms/visibility')
  
        # used by abbreviated pipeline, only
        def outbound_predicates_to_properties
          @outbound_predicates_to_properties ||=
            outbound_statements.predicates.map { |p| [p, factory.properties.detect { |_key, value| value.predicate == p }&.first] }.to_h.merge(VISIBILITY => 'visibility')
        end
    end
  end
end
