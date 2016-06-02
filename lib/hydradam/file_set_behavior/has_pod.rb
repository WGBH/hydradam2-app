require 'depends_on'
 
module HydraDAM
  module FileSetBehavior
    module HasPod
      extend ActiveSupport::Concern
 
      included do 
        # Ensure class dependencies
        include DependsOn
        depends_on(ActiveFedora::Base)

        # TODO use correct predicates for Unit of Origin properties
        property :unit_of_origin, predicate: RDF::Vocab::EBUCore.description do |index|
          index.as :stored_searchable, :facetable
        end

        # Ensure module dependencies
        include ::CurationConcerns::FileSetBehavior
      end
 
      def assign_properties_from_pod
        noko = parent.pod_xml.noko.dup
        noko.remove_namespaces!
        self.unit_of_origin += [noko.xpath('//assignment/unit').text]
      end


    end
  end
end
