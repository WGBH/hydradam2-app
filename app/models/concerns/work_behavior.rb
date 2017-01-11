require 'hydradam/file_set_behavior/has_ffprobe'
require 'rubygems'
require 'rdf'

module Concerns
  module WorkBehavior
    extend ActiveSupport::Concern
    included do
      contains :mdpi_xml, class_name: "XMLFile"
      contains :mods_xml, class_name: "XMLFile"
      contains :pod_xml, class_name: "XMLFile"

      # From mdpi_xml
      
      # Predicate is same as context.yml for this property
      property :digitized_by_entity, predicate: RDF::Vocab::EBUCore.hasCreator do |index| 
        index.as :stored_searchable, :facetable
      end
      
      # Predicate is same as context.yml for this property
      property :digitized_by_staff, predicate: RDF::Vocab::EBUCore.hasMetadataAttributor do |index|
        index.as :stored_searchable, :facetable
      end
      
      # I do not know if this is needed as of now as the property is eracsed from the Google doc     
      property :mdpi_date, predicate: RDF::Vocab::EBUCore.dateDigitised, multiple: false do |index|
        index.as :stored_searchable, :sortable, :facetable
      end
      
      # Predicate is not same as context.yml for this property
      property :extraction_workstation, predicate: RDF::Vocab::EBUCore.textualAnnotation do |index|
        index.as :stored_searchable, :facetable
      end
      
      # Predicate is same as context.yml for this property
      property :digitization_comments, predicate: RDF::Vocab::EBUCore.comments do |index|
        index.as :stored_searchable
      end
      
       # Predicate is same as context.yml for this property
      property :original_identifier, predicate: RDF::Vocab::EBUCore.hasSource do |index|
        index.as :symbol
      end
      
      # Predicate is same as context.yml for this property
      property :definition, predicate: RDF::Vocab::EBUCore.hasVideoFormat do |index|
        index.as :stored_searchable, :facetable
      end
      
      property :original_media_damage, predicate: RDF::Vocab::SKOS.historyNote do |index|
        index.as :stored_sortable, :facetable
      end
      
      property :original_media_preservation_problem, predicate: RDF::SKOS.scopeNote  do |index|
        index.as :stored_sortable, :facetable
      end
      
      property :qc_status, predicate: RDF::SKOS.changeNote  do |index|
        index.as :stored_sortable, :facetable, :stored_searchable
      end
      
      property :manual_qc_check, predicate: RDF::SKOS.changeNote do |index|
        index.as :stored_sortable, :facetable, :stored_searchable
      end
      
      property :encoder_manufacturer, predicate: RDF::Vocab::PREMIS.hasHardwareOtherInformation do |index|
        index.as :stored_searchable
      end
      
      property :ad_manufacturer, predicate: RDF::Vocab::PREMIS.hasHardwareName do |index|
        index.as :stored_searchable
      end
      
      property :speed_used, predicate: RDF::Vocab::EBUCore.playbackSpeed do |index|
        index.as :stored_searchable
      end
      
      property :tbc_manufacturer, predicate: RDF::Vocab::PREMIS.hasHardwareName do |index|
        index.as :stored_searchable
      end
      
      #property :tape_thickness, predicate: RDF::Vocab::DCTERMS.description do |index|
      #  index.as :stored_searchable
      #end
      
      property :total_parts, predicate: RDF::Vocab::EBUCore.partTotalNumber 
     
      # From mods_xml
      # :title property included in core behaviors

      # From pod_xml
      
      # The attribute name is identifier in Google doc and the Predicate is same as context.yml for this property
      property :mdpi_barcode, predicate: RDF::Vocab::EBUCore.identifier, multiple: false do |index|
        index.as :symbol
      end
      
       # Predicate is not same as context.yml for this property      
      property :unit_of_origin, predicate: RDF::Vocab::EBUCore.isOwnedBy do |index|
        index.as :stored_searchable, :facetable
      end
      
       # Predicate is not same as context.yml for this property    
      property :original_format, predicate: RDF::Vocab::EBUCore.hasFormat do |index|
        index.as :stored_searchable, :facetable
      end
      
      # Predicate is same as context.yml for this property
      property :recording_standard, predicate: RDF::Vocab::EBUCore.hasStandard do |index|
        index.as :stored_searchable, :facetable
      end
      
      # Predicate is same as context.yml for this property
      property :image_format, predicate: RDF::Vocab::EBUCore.aspectRatio do |index|
        index.as :stored_searchable, :facetable
      end

    end

    def access_copy
      members_of_quality_level(:access).first
    end

    def preservation_copy
      members_of_quality_level(:preservation).first
    end

    def production_copy
      members_of_quality_level(:production).first
    end

    def members_of_quality_level(quality_level)
      ordered_members.to_a.select { |member| member.try(:quality_level) == quality_level.to_s }
    end
  end
end
