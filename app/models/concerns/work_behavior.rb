require 'hydradam/file_set_behavior/has_ffprobe'


module Concerns
  module WorkBehavior
    extend ActiveSupport::Concern
    included do
      contains :mdpi_xml, class_name: "XMLFile"
      contains :mods_xml, class_name: "XMLFile"
      contains :pod_xml, class_name: "XMLFile"

      property :mdpi_date, predicate: RDF::Vocab::EBUCore.dateCreated, multiple: false
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
    end

    def assign_properties_from_mods_xml
      noko = mods_xml.noko.dup
      noko.remove_namespaces!
      self.title += [noko.xpath('/mods/titleInfo/title').text]
    end

    def assign_properties_from_pod_xml
      noko = mods_xml.noko.dup
      noko.remove_namespaces!
      #self.title += [noko.xpath('/mods/titleInfo/title').text]
    end
  end
end
