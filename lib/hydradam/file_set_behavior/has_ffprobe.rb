require 'depends_on'
 
module HydraDAM
  module FileSetBehavior
    module HasFfprobe
      extend ActiveSupport::Concern
 
      included do 
        # Ensure class dependencies
        include DependsOn
        depends_on(ActiveFedora::Base)

        property :quality_level, predicate: RDF::Vocab::EBUCore.encodingLevel, multiple: false do |index|
          index.as :stored_searchable, :facetable
        end
        property :file_format, predicate: RDF::Vocab::EBUCore.hasFormat do |index|
          index.as :stored_searchable, :facetable
        end
        property :file_format_long_name, predicate: RDF::Vocab::EBUCore.hasFileFormat do |index|
          index.as :stored_searchable, :facetable
        end
        property :codec_type, predicate: RDF::Vocab::EBUCore.hasMedium do |index|
          index.as :stored_searchable, :facetable
        end
        property :codec_name, predicate: RDF::Vocab::EBUCore.hasCodec do |index|
          index.as :stored_searchable, :facetable
        end
        property :codec_long_name, predicate: RDF::Vocab::EBUCore.codecName do |index|
          index.as :stored_searchable, :facetable
        end
        property :format_duration, predicate: RDF::Vocab::EBUCore.duration do |index|
          index.as :stored_searchable, :sortable, :facetable
        end
        property :bit_rate, predicate: RDF::Vocab::EBUCore.bitRate do |index|
          index.as :stored_searchable, :sortable, :facetable
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

        self.filename = noko.xpath('//ffprobe/format/@filename').text
        self.file_format += [noko.xpath('//ffprobe/format/@format_name').text]
        self.file_format_long_name += [noko.xpath('//ffprobe/format/@format_long_name').text]
        self.file_size += [noko.xpath('//ffprobe/format/@size').text.to_i]
        self.bit_rate += [noko.xpath('//ffprobe/format/@bit_rate').text.to_i]
        self.codec_type += noko.xpath('//ffprobe/streams/stream/@codec_type').collect { |i| i.text }
        self.codec_name += noko.xpath('//ffprobe/streams/stream/@codec_name').collect { |i| i.text }
        self.codec_long_name += noko.xpath('//ffprobe/streams/stream/@codec_long_name').collect { |i| i.text }
        self.format_duration += [noko.xpath('//ffprobe/format/@duration').text.to_i]
      end


    end
  end
end
