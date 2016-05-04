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
          index.as :symbol
        end

        # property :fileSize, predicate: RDF::Vocab::EBUCore.fileSize, multiple: false do |index|
        #   # index.as Solrizer::Descriptor.new(:long, :stored, :searchable)
        # end

 
        # Ensure module dependencies
        include Hydra::Works::FileSetBehavior
 
         # TODO: replace bogus predicate with legit one.
        directly_contains_one :ffprobe, through: :files, type: ::RDF::URI('http://example.org/TODO-replace-with-actual-predicate'), class_name: 'XMLFile'
      end
 
      def assign_properties_from_ffprobe
         noko = ffprobe.noko.dup
         noko.remove_namespaces!
         self.filename = noko.xpath('//ffprobe/format/@filename').text
         self.file_format += [noko.xpath('//ffprobe/format/@format_long_name').text]
         self.file_size += [noko.xpath('//ffprobe/format/@size').text.to_i]
       end
     end
  end
end
