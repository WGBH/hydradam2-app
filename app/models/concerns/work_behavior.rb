require 'hydradam/file_set_behavior/has_ffprobe'


module Concerns
  module WorkBehavior
    extend ActiveSupport::Concern
    included do
      contains :mdpi_xml, class_name: "XMLFile"
      contains :mods_xml, class_name: "XMLFile"
      contains :pod_xml, class_name: "XMLFile"

      # From mdpi_xml
      property :digitized_by_entity, predicate: RDF::Vocab::EBUCore.hasCreator do |index|
        index.as :stored_searchable, :facetable
      end
      property :digitized_by_staff, predicate: RDF::Vocab::EBUCore.hasMetadataAttributor do |index|
        index.as :stored_searchable, :facetable
      end
      property :mdpi_date, predicate: RDF::Vocab::EBUCore.dateDigitised, multiple: false do |index|
        index.as :stored_searchable, :sortable, :facetable
      end
      property :extraction_workstation, predicate: RDF::Vocab::EBUCore.textualAnnotation do |index|
        index.as :stored_searchable, :facetable
      end
      property :digitization_comments, predicate: RDF::Vocab::EBUCore.comments do |index|
        index.as :stored_searchable
      end
      property :original_identifier, predicate: RDF::Vocab::EBUCore.hasSource do |index|
        index.as :symbol
      end
      property :definition, predicate: RDF::Vocab::EBUCore.hasVideoFormat do |index|
        index.as :stored_searchable, :facetable
      end



      # From mods_xml
      # :title property included in core behaviors

      # From pod_xml
      property :mdpi_barcode, predicate: RDF::Vocab::EBUCore.identifier, multiple: false do |index|
        index.as :symbol
      end
      property :unit_of_origin, predicate: RDF::Vocab::EBUCore.isOwnedBy do |index|
        index.as :stored_searchable, :facetable
      end
      property :original_format, predicate: RDF::Vocab::EBUCore.hasFormat do |index|
        index.as :stored_searchable, :facetable
      end
      property :recording_standard, predicate: RDF::Vocab::EBUCore.hasStandard do |index|
        index.as :stored_searchable, :facetable
      end
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

    def assign_properties_from_mdpi_xml
      noko = mdpi_xml.noko.dup
      noko.remove_namespaces!
      #self.title += [noko.xpath('/IU/Carrier/Barcode').text]
      self.mdpi_date = DateTime.parse(noko.xpath('/IU/Carrier/Parts/Part/Ingest/Date').text)
      self.digitized_by_entity += [noko.xpath('/IU/Carrier/Parts/DigitizingEntity').text]
      self.digitized_by_staff += noko.xpath('/IU/Carrier/Parts/Part/Ingest/Created_by').collect { |i| i.text }
      workstation = [noko.xpath('/IU/Carrier/Parts/Part/Ingest/Extraction_workstation/Manufacturer').text,
          noko.xpath('/IU/Carrier/Parts/Part/Ingest/Extraction_workstation/Model').text,
          noko.xpath('/IU/Carrier/Parts/Part/Ingest/Extraction_workstation/SerialNumber').text].join(' ')
      self.extraction_workstation += [workstation]
      self.digitization_comments += [noko.xpath('//Comments').text]
      self.original_identifier += [noko.xpath('/IU/Carrier/Identifier').text]
      self.definition += [noko.xpath('/IU/Carrier/Definition').text]

    end

    def assign_properties_from_mods_xml
      noko = mods_xml.noko.dup
      noko.remove_namespaces!
      self.title += [noko.xpath('/mods/titleInfo/title').text]
    end

    def assign_properties_from_pod_xml
      noko = pod_xml.noko.dup
      noko.remove_namespaces!
      self.mdpi_barcode = noko.xpath('//details/mdpi_barcode').text
      self.unit_of_origin += [noko.xpath('//assignment/unit').text]
      self.original_format += [noko.xpath('//technical_metadata/format').text]
      self.recording_standard += [noko.xpath('//technical_metadata/recording_standard').text]
      self.image_format += [noko.xpath('//technical_metadata/image_format').text]

    end
  end
end
