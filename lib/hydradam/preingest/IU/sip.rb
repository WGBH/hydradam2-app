module HydraDAM
  module Preingest
    module IU
      class Tarball
        def initialize(preingest_file)
          @preingest_file = preingest_file
          parse
        end
        attr_reader :preingest_file
        attr_reader :work_attributes, :file_set_attributes, :source_metadata, :file_sets, :sources

        def resource_class
          Work
        end

        def source_metadata
          nil
        end

        def parse
          @work_attributes = {}
          @file_set_attributes = {}
          @source_metadata = nil
          @file_sets = []
          @sources = []

          filenames.each { |filename| process_file(filename) }
          postprocess
          delete_extracted_files!
        end

        def tarball_entries
          @tarball_entries ||= begin
            File.open(@preingest_file, 'rb') do |file|
              Archive::Tar::Minitar.open(file).map{ |entry| entry }.to_a
            end
          end
        end
    
        def filenames
          @filenames ||= Dir["#{root_dir}/*"]
        end
    
        def root_dir
          @root_dir ||= begin
            root_dir_parent = File.dirname(@preingest_file)
            Archive::Tar::Minitar.unpack(@preingest_file, root_dir_parent)
            root_dir_basename = tarball_entries.select{ |tar_entry| tar_entry.directory? }.first.name
            File.expand_path(root_dir_basename, root_dir_parent)
          end
        
          raise ExtractionError unless File.directory?(@root_dir)
          @root_dir 
        end
    
        def delete_extracted_files!
          FileUtils.remove_entry_secure(root_dir)
        end
            
        def process_file(filename)
          file_hash = { filename: filename.sub(/.*\//, '') }
          file_reader = HydraDAM::Preingest::FileReader.new(filename)
          unless file_reader&.type.nil?
            work_ai = HydraDAM::Preingest::AttributeIngester.new(file_reader.id, file_reader.attributes, factory: resource_class)
            file_set_ai = HydraDAM::Preingest::AttributeIngester.new(file_reader.id, file_reader.file_attributes, factory: FileSet)
            if file_reader.type.in? [:pod, :mods, :mdpi]
              @work_attributes[file_reader.type] = work_ai.raw_attributes
              @file_set_attributes[file_reader.type] = file_set_ai.raw_attributes
              file_hash[:files] = file_reader.files
            elsif file_reader.type.in? [:purl, :md5]
              @purls_map = file_reader.reader.purls_map if file_reader.type == :purl
              @md5sums_map = file_reader.reader.md5sums_map if file_reader.type == :md5
              file_hash[:files] = file_reader.files
            else
              file_hash[:attributes] = file_set_ai.raw_attributes
              file_hash[:files] = file_reader.files
            end
          end
          @file_sets << file_hash if file_hash.present?
        end
    
        def md5sums_map
          @md5sums_map ||= {}
        end

        def purls_map
          @purls_map ||= {}
        end
  
        def postprocess
          @file_sets.each do |file_set|
            if file_set[:files].present?
              file_set[:files].each do |file_hash|
                if filename = file_hash[:filename]
                  file_hash[:md5sum] = md5sums_map[filename] if md5sums_map[filename]
                  file_hash[:purl] = purls_map[filename] if purls_map[filename]
                end
              end
            end
          end
        end
      end
    end

    class FileReader
      def initialize(filename)
        @filename = filename
        @reader = reader_class.new(filename, File.read(filename))
      end
      attr_reader :filename, :reader

      delegate :id, :attributes, :file_attributes, :files, :type, to: :reader

      def reader_class
        case @filename
        when /pod\.xml$/
          PodReader
        when /mods\.xml$/
          ModsReader
        when /4\d{3}\.xml$/
          BarcodeReader
        when /ffprobe\.xml$/
          FFProbeReader
	when /purl.*ya?ml$/
          PurlReader
	when /\/manifest-md5\.txt$/
	  Md5Reader
        else
          NullReader # raise exception?
        end
      end
    end
    class NullReader
      def initialize(id, source)
        @id = id
        @source = source
      end
      attr_reader :id, :source

      def type
        nil
      end
      
      def attributes
        {}
      end
    end
    class AbstractReader
      def initialize(id, source)
        @id = id
        @source = source
        @mime_type = 'application/octet-stream'
      end
      attr_reader :id, :source, :mime_type

      def parse
      end

      # for Work metadata
      def attributes
        {}
      end

      # for fileset metadata run through AttributeIngester
      def file_attributes
        {}
      end

      def files
         file_list = [metadata_file]
         file_list << media_file if media_file
         file_list
      end
      def metadata_file
        { mime_type: mime_type,
          path: id,
          filename: id.to_s.sub(/.*\//, ''),
          file_opts: {},
        }
      end
      def media_file
      end
    end
    class XmlReader < AbstractReader
      def initialize(id, source)
        @id = id
        @source = source
        @mime_type = 'application/xml'
        @xml = Nokogiri::XML(source).remove_namespaces!
        parse
      end
      attr_reader :xml

      def type
        :xml
      end

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

      def type
        :pod
      end

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
      def type
        :mods
      end
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

      def type
        :mdpi
      end

      def attributes
        result = super
        result[:mdpi_date] = DateTime.parse(result[:mdpi_date].first)
        result[:total_parts] = xml.xpath('count(//Part)').to_i
        result
      end
    end
    
    class FFProbeReader < XmlReader
      WORK_ATT_LOOKUPS = {} # No WORK attributes from FFProbe
      FILE_ATT_LOOKUPS = {
        file_format: '//ffprobe/format/@format_name',
        file_format_long_name: '//ffprobe/format/@format_long_name',
        codec_type: '//ffprobe/streams/stream/@codec_type',
        codec_name: '//ffprobe/streams/stream/@codec_name',
        codec_long_name: '//ffprobe/streams/stream/@codec_long_name',
        duration: '//ffprobe/format/@duration',
        bit_rate: '//ffprobe/format/@bit_rate',
        file_name: '//ffprobe/format/@filename',
        file_size: '//ffprobe/format/@size',
        sample_rate: '//ffprobe/streams/stream/@sample_rate',
        video_width: '//ffprobe/streams/stream/@width',
        video_height: '//ffprobe/streams/stream/@height'
      }

      def type
        :ffprobe
      end

      def media_file
        { mime_type: 'FIXME',
          filename: file_attributes[:file_name].first&.to_s.sub(/.*\//, ''),
          file_opts: {}
        }
      end
    end

    class YamlReader < AbstractReader
      def initialize(id, source)
        @id = id
        @source = source
        @mime_type = 'application/x-yaml'
        @yaml = Psych.load(@source)
        parse
      end
      attr_reader :yaml
    end

    class PurlReader < YamlReader
      attr_reader :purls_map
      def type
        :purl
      end
      def parse
        @purls_map = {}
        @yaml.each do |media, values|
          @purls_map[media] = values['purl']
        end
      end
    end

    class TextReader < AbstractReader
      def initialize(id, source)
        @id = id
        @source = source
        @mime_type = 'text/plain'
        parse
      end
    end

    class Md5Reader < TextReader
      attr_reader :md5sums_map
      def type
        :md5
      end
      def parse
        @md5sums_map = source.split("\n").map { |line| line.split(/\s+/).reverse }.map { |pair| pair[0] = pair[0].sub(/.*\//, ''); pair }.to_h
      end
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
