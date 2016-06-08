require 'depends_on'
 
module HydraDAM
  module FileSetBehavior
    module HasMDPI
      extend ActiveSupport::Concern
 
      included do 
        # Ensure class dependencies
        include DependsOn
        depends_on(ActiveFedora::Base)

        property :date_generated, predicate: RDF::Vocab::EBUCore.dateDigitised do |index|
          index.as :stored_searchable, :sortable, :facetable
        end

        # Ensure module dependencies
        include ::CurationConcerns::FileSetBehavior
      end
 
      def assign_properties_from_mdpi
        noko = parent.mdpi_xml.noko.dup
        noko.remove_namespaces!
        raw_date = noko.xpath('/IU/Carrier/Parts/Part/Ingest/Date').text
        self.date_generated += [Date.parse(raw_date)] unless raw_date.blank?
      end


    end
  end
end
