require 'depends_on'
 
module HydraDAM
  module FileSetBehavior
    module HasMods
      extend ActiveSupport::Concern
 
      included do 
        # Ensure class dependencies
        include DependsOn
        depends_on(ActiveFedora::Base)

        property :title, predicate: RDF::Vocab::EBUCore.title do |index|
          index.as :stored_searchable, :facetable
        end

        # Ensure module dependencies
        include ::CurationConcerns::FileSetBehavior
      end
 
      def assign_properties_from_mods
        noko = parent.mods_xml.noko.dup
        noko.remove_namespaces!
        self.title += [noko.xpath('/mods/titleInfo/title').text]
      end


    end
  end
end
