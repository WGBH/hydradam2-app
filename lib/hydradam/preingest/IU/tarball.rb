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
          @md5sums_map = {}
          @md5events_map = {}
          @creation_events_map = {}
          @purls_map = {}
          @parts_map = {}
          @date_generated_map = {}

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
          unless file_reader.type.nil?
            work_ai = HydraDAM::Preingest::AttributeIngester.new(file_reader.id, file_reader.attributes, factory: resource_class)
            file_set_ai = HydraDAM::Preingest::AttributeIngester.new(file_reader.id, file_reader.file_attributes, factory: FileSet)
            if file_reader.type.in? [:pod, :mods, :mdpi]
              @work_attributes[file_reader.type] = work_ai.raw_attributes
              @file_set_attributes[file_reader.type] = file_set_ai.raw_attributes
              # MDPI value "wins" over manifest value
              @md5sums_map.merge!(file_reader.reader.md5sums_map) if file_reader.type == :mdpi
              @md5events_map = array_merge(@md5events_map, file_reader.reader.md5events_map) if file_reader.type == :mdpi
              @creation_events_map = file_reader.reader.creation_events_map if file_reader.type == :mdpi
              @parts_map = file_reader.reader.parts_map if file_reader.type == :mdpi
              @date_generated_map = file_reader.reader.date_generated_map if file_reader.type == :mdpi
              file_set[:files] = file_reader.files
            elsif file_reader.type.in? [:purl, :md5]
              @purls_map = file_reader.reader.purls_map if file_reader.type == :purl
              @md5sums_map = file_reader.reader.md5sums_map.merge(@md5sums_map) if file_reader.type == :md5
              @md5events_map = array_merge(@md5events_map, file_reader.reader.md5events_map) if file_reader.type == :md5
              file_set[:files] = file_reader.files
            else
              file_set[:attributes] = file_set_ai.raw_attributes
              file_set[:files] = file_reader.files
            end
            file_set[:events] = file_reader.events if file_reader.events
          end
          @file_sets << file_set if file_set.present?
        end
    
        def array_merge(h1, h2)
          h = {}
          h1 ||= {}
          h2 ||= {}
          keys = h1.keys.sort | h2.keys.sort
          keys.each do |k|
            h[k] = Array.wrap(h1[k]) + Array.wrap(h2[k])
          end
          h
        end
  
        def postprocess
          @file_sets.each do |file_set|
            if file_set[:files].present?
              file_set[:files].each do |file|
                if file[:filename]
                  file[:md5sum] = @md5sums_map[file[:filename]] if @md5sums_map[file[:filename]]
                  file[:purl] = @purls_map[file[:filename]] if @purls_map[file[:filename]]
                end
              end
              # FIXME: media file wins, if available?
              file_set[:filename] = file_set[:files].last[:filename]
              # FIXME: this bypasses attribute ingester...
              file_set[:attributes][:md5_checksum] = Array.wrap(file_set[:files].last[:md5sum]) if file_set[:attributes].present?
            end
            if @md5events_map && @md5events_map[file_set[:filename]]
              file_set[:events] ||= []
              file_set[:events] += @md5events_map[file_set[:filename]]
            end
            if @creation_events_map && @creation_events_map[file_set[:filename]]
              file_set[:events] ||= []
              file_set[:events] << @creation_events_map[file_set[:filename]]
            end
            if @parts_map && @parts_map[file_set[:filename]]
              file_set[:attributes][:part] = @parts_map[file_set[:filename]]
            end
            if @date_generated_map && @date_generated_map[file_set[:filename]]
              file_set[:attributes][:date_generated] = @date_generated_map[file_set[:filename]]
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

        def filename
          id.to_s.sub(/.*\//, '')
        end

        def metadata_file
          { mime_type: mime_type,
            path: id,
            filename: id.to_s.sub(/.*\//, ''),
            file_opts: {},
            use: use(filename).to_s
          }
        end

        def use(_file_name_pattern)
          :original_file
        end

        def media_file
        end

        def events
        end

        def md5sums_map_to_events(mapping, agent: 'mailto@mdpi.iu.edu')
          results = {}
          mapping.each do |filename, checksum|
            atts = {}
            atts[:premis_event_type] = ['mes']
            atts[:premis_agent] = [agent]
            atts[:premis_event_date_time] = Array.wrap(DateTime.parse(File.mtime(id).to_s).to_s)
            atts[:premis_event_detail] = ['Program used: python, hashlib.sha256()'] #FIXME: vary
            atts[:premis_event_outcome] = [checksum]
            results[filename] = { attributes: atts }
          end
          results
        end

        def creation_dates_to_events(mapping, agent: 'mailto@mdpi.iu.edu')
          results = {}
          mapping.each do |filename, date|
            atts = {}
            atts[:premis_event_type] = ['cre']
            atts[:premis_agent] = [agent]
            atts[:premis_event_date_time] = Array.wrap(date)
            atts[:premis_event_detail] = ['File created']
            results[filename] = { attributes: atts }
          end
          results
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
        attr_reader :md5sums_map, :md5events_map, :creation_events_map
        attr_reader :parts_map, :date_generated_map
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
        FILE_ATT_LOOKUPS = {}
  
        def type
          :mdpi
        end
  
        def attributes
          result = super
          result[:mdpi_date] = DateTime.parse(result[:mdpi_date].first)
          result[:total_parts] = xml.xpath('count(//Part)').to_i
          result
        end

        def parse
          # FIXME: unify values mapping into single block?
          @md5sums_map = {}
          xml.xpath('//Files/File').each do |file|
            @md5sums_map[file.xpath('FileName').first.text.to_s] = file.xpath('CheckSum').first.text.to_s
          end
          @md5events_map = md5sums_map_to_events(md5sums_map)

          @creation_dates = {}
          xml.xpath('//Parts/Part').each do |part|
            date = DateTime.parse(part.xpath('Ingest/Date').text.to_s).to_s
            part.xpath('Files/File').each do |file|
              @creation_dates[file.xpath('FileName').first.text.to_s] = date
            end
          end
          @creation_events_map = creation_dates_to_events(@creation_dates)

          @parts_map = {}
          xml.xpath('//Parts/Part').each do |part|
            side = part.xpath('@Side').text.to_i
            part.xpath('Files/File').each do |file|
              @parts_map[file.xpath('FileName').first.text.to_s] = side
            end
          end

          @date_generated_map = {}
          xml.xpath('//Parts/Part').each do |part|
            date = part.xpath('Ingest/Date').text.to_s
            part.xpath('Files/File').each do |file|
              @date_generated_map[file.xpath('FileName').first.text.to_s] = date
            end
          end
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

        def media_filename
          file_attributes[:file_name].first.to_s.sub(/.*\//, '')
        end

        def media_file
          { mime_type: mimetype(media_filename),
            filename: media_filename,
            file_opts: {},
            use: use(media_filename).to_s
          }
        end

        def use(file_name_pattern)
          case file_name_pattern
          when /_ffprobe/
            :extracted_text
          when /_access/
            :service_file
          when /_pres/
            :preservation_master_file
          when /_prod/
            :intermediate_file
          else
            :original_file
          end
        end

        # FIXME: determine mimetype from codec, instead?
        def mimetype(file_name_pattern)
          case file_name_pattern
          when /mp4$/
            'video/mp4'
          when /wav$/
            'audio/wav'
          when /wmf$/
            'application/wmf'
          when /xml$/
            'application/xml'
          when /yml$/
            'application/x-yaml'
          else
            'application/octet-stream'
          end
        end

        def events
          results = []
          val_atts = {}
          val_atts[:premis_event_type] = ['val']
          val_atts[:premis_agent] = ['mailto:fixme@fixme.fixme']
          val_atts[:premis_event_date_time] = Array.wrap(DateTime.parse(File.mtime(id).to_s).to_s)
          val_atts[:premis_event_detail] = ['FFprobe multimedia streams analyzer from FFmpeg']
          val_atts[:premis_event_outcome] = ['PASS']
          results << { attributes: val_atts }
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
        attr_reader :md5sums_map, :md5events_map
        def type
          :md5
        end
        def parse
          @md5sums_map = source.split("\n").map { |line| line.split(/\s+/).reverse }.map { |pair| pair[0] = pair[0].sub(/.*\//, ''); pair }.to_h
          @md5events_map ||= md5sums_map_to_events(@md5sums_map, agent: 'store-admin@iu.edu')
        end
      end
    end
  end
end
