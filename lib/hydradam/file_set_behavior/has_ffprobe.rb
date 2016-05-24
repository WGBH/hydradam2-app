require 'depends_on'
 
module HydraDAM
  module FileSetBehavior
    module HasFfprobe
      extend ActiveSupport::Concern
 
      included do 
        # Ensure class dependencies
        include DependsOn
        depends_on(ActiveFedora::Base)

        property :file_format, predicate: RDF::Vocab::EBUCore.hasFileFormat do |index|
          index.as :stored_searchable
        end
        property :file_format_long_name, predicate: RDF::Vocab::EBUCore.hasFileFormat do |index|
          index.as :symbol
        end
        property :codec_type, predicate: RDF::Vocab::EBUCore.hasMedium do |index|
          index.as :stored_searchable
        end
        property :codec_name, predicate: RDF::Vocab::EBUCore.codecName do |index|
          index.as :stored_searchable
        end
        property :codec_long_name, predicate: RDF::Vocab::EBUCore.codecName do |index|
          index.as :stored_searchable
        end
        property :duration, predicate: RDF::Vocab::EBUCore.duration do |index|
          index.as :stored_searchable
        end
        property :bit_rate, predicate: RDF::Vocab::EBUCore.bitRate do |index|
          index.as :stored_searchable
        end
        property :date_generated, predicate: RDF::Vocab::EBUCore.dateDigitised do |index|
          index.as :stored_searchable
        end
        property :unit_of_origin, predicate: RDF::Vocab::EBUCore.description do |index|
          index.as :stored_searchable
        end
        property :unit_of_origin_statement, predicate: RDF::Vocab::EBUCore.description do |index|
          index.as :stored_searchable
        end
        property :alt_unit_of_origin_statement, predicate: RDF::Vocab::EBUCore.description do |index|
          index.as :stored_searchable
        end



        # property :fileSize, predicate: RDF::Vocab::EBUCore.fileSize, multiple: false do |index|
        #   # index.as Solrizer::Descriptor.new(:long, :stored, :searchable)
        # end

 
        # Ensure module dependencies
        include ::CurationConcerns::FileSetBehavior
 
         # TODO: replace bogus predicate with legit one.
        directly_contains_one :ffprobe, through: :files, type: ::RDF::URI('http://example.org/TODO-replace-with-actual-predicate'), class_name: 'XMLFile'
      end
 
      def assign_properties_from_ffprobe
        noko = ffprobe.noko.dup
        noko.remove_namespaces!
        self.title += [noko.xpath('//ffprobe/format/tag[@key="title"]/@value').text]
        raw_date = noko.xpath('//ffprobe/format/tag[@key="date"]/@value').text
        self.date_generated += [Date.parse(raw_date)] unless raw_date.blank?
        self.unit_of_origin += [noko.xpath('//ffprobe/format/tag[@key="IARL"]/@value').text]
        self.unit_of_origin_statement += [noko.xpath('//ffprobe/format/tag[@key="comment"]/@value').text]
        self.alt_unit_of_origin_statement += [noko.xpath('//ffprobe/format/tag[@key="description"]/@value').text]
        self.filename = noko.xpath('//ffprobe/format/@filename').text
        self.file_format += [noko.xpath('//ffprobe/format/@format_name').text]
        self.file_format_long_name += [noko.xpath('//ffprobe/format/@format_long_name').text]
        self.file_size += [noko.xpath('//ffprobe/format/@size').text.to_i]
        self.bit_rate += [noko.xpath('//ffprobe/format/@bit_rate').text.to_i]
        self.codec_type += [noko.xpath('//ffprobe/streams/stream/@codec_type').text]
        self.codec_name += [noko.xpath('//ffprobe/streams/stream/@codec_name').text]
        self.codec_long_name += [noko.xpath('//ffprobe/streams/stream/@codec_long_name').text]
        self.duration += [noko.xpath('//ffprobe/format/@duration').text.to_i]
      end
     end
  end
end
