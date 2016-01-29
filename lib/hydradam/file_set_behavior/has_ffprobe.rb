require 'depends_on'

  module HydraDAM
    module FileSetBehavior
      module Hasffprobe
        extend ActiveSupport::Concern
 
       included do
 
         # Ensure class dependencies
         include DependsOn
         depends_on(ActiveFedora::Base)
 
        # Ensure module dependencies
        include Hydra::Works::FileSetBehavior
 
         # TODO: replace bogus predicate with legit one.
        directly_contains_one :ffprobe, through: :files, type: ::RDF::URI('http://example.org/TODO-replace-with-actual-predicate'), class_name: 'XMLFile'
      end
    end
  end
 end 
 require 'depends_on'
 
 module HydraDAM
   module FileSetBehavior
     module Hasffprobe
       extend ActiveSupport::Concern
 
       included do
 
         # Ensure class dependencies
         include DependsOn
         depends_on(ActiveFedora::Base)
 
         # Ensure module dependencies
         include Hydra::Works::FileSetBehavior
 
         # TODO: replace bogus predicate with legit one.
        directly_contains_one :ffprobe, through: :files, type: ::RDF::URI('http://example.org/TODO-replace-with-actual-predicate'), class_name: 'XMLFile'
 
        apply_schema Hydra::Works::Characterization::BaseSchema, Hydra::Works::Characterization::AlreadyThereStrategy
       end
 
      def assign_properties_from_ffprobe
         noko = ffprobe.noko.dup
         noko.remove_namespaces!
         self.filename = noko.xpath('//FileName').text
       end
     end
  end
 end 
