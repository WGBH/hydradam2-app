# FIXME: better configure library includes
require './lib/hydradam/preingest/attribute_ingester.rb'

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
            root_dir_basename = tarball_entries.select{ |tar_entry| tar_entry.directory? }.first.name
            File.expand_path(root_dir_basename, root_dir_parent)
          end
        
          raise "Directory not present: #{@root_dir}" unless File.directory?(@root_dir)
          @root_dir 
        end
    
        def process_file(filename)
          file_set = { filename: filename.sub(/.*\//, '') }
          file_reader = HydraDAM::Preingest::IU::FileReader.new(filename)
          unless file_reader&.type.nil?
            work_ai = HydraDAM::Preingest::AttributeIngester.new(file_reader.id, file_reader.attributes, factory: resource_class)
            file_set_ai = HydraDAM::Preingest::AttributeIngester.new(file_reader.id, file_reader.file_attributes, factory: FileSet)
            if file_reader.type.in? [:pod, :mods, :mdpi]
              @work_attributes[file_reader.type] = work_ai.raw_attributes
              @file_set_attributes[file_reader.type] = file_set_ai.raw_attributes
              file_set[:files] = file_reader.files
            elsif file_reader.type.in? [:purl, :md5]
              @purls_map = file_reader.reader.purls_map if file_reader.type == :purl
              @md5sums_map = file_reader.reader.md5sums_map if file_reader.type == :md5
              file_set[:files] = file_reader.files
            else
              file_set[:attributes] = file_set_ai.raw_attributes
              file_set[:files] = file_reader.files
            end
            file_set[:events] = file_reader.events if file_reader.events
          end
          @file_sets << file_set if file_set.present?
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
              file_set[:files].each do |file|
                if file[:filename]
                  file[:md5sum] = md5sums_map[file[:filename]] if md5sums_map[file[:filename]]
                  file[:purl] = purls_map[file[:filename]] if purls_map[file[:filename]]
                end
              end
              # FIXME: media file wins, if available?
              file_set[:filename] = file_set[:files].last[:filename]
              # FIXME: this bypasses attribute ingester...
              file_set[:attributes][:md5_checksum] = Array.wrap(file_set[:files].last[:md5sum]) if file_set[:attributes].present?
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
  
        delegate :id, :attributes, :file_attributes, :files, :events, :type, to: :reader
  
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

        def events
          nil
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
        def events
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
          format_duration: '//ffprobe/format/@duration',
          bit_rate: '//ffprobe/format/@bit_rate',
          file_name: '//ffprobe/format/@filename',
          file_size: '//ffprobe/format/@size',
          format_sample_rate: '//ffprobe/streams/stream/@sample_rate',
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

        def events
          results = []
          attributes = {}
          attributes[:premis_event_type] = ['val']
          attributes[:premis_agent] = ['mailto:' + User.first&.email]
          # FIXME: Minitar's unpack does not allow --atime-preserve argument, to maintain timestamps
          attributes[:premis_event_date_time] = Array.wrap(File.mtime(id))          
          attributes[:premis_event_detail] = ['FFprobe multimedia streams analyzer from FFmpeg']
          attributes[:premis_event_outcome] = ['PASS']
          results << { attributes: attributes }
          attributes = {}
          attributes[:premis_event_type] = ['cre']
          attributes[:premis_agent] = ['mailto:' + User.first&.email]
          attributes[:premis_event_date_time] = Array.wrap(File.mtime(id))
	  # attributes[:premis_event_detail] = ['FFprobe multimedia streams analyzer from FFmpeg']
          results << { attributes: attributes }
	  attributes = {}
          attributes[:premis_event_type] = ['mes']
          attributes[:premis_agent] = ['mailto:' + User.first&.email]
          attributes[:premis_event_date_time] = Array.wrap(File.mtime(id))
	  # attributes[:premis_event_detail] = ['FFprobe multimedia streams analyzer from FFmpeg']
	  # FIXME: add :premis_event_outcome for this event
	  attributes[:premis_event_outcome] = Array.wrap(File.checksum)
          results << { attributes: attributes }
          results
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
    end
  end
end
