require 'hydradam/file_set_behavior/has_ffprobe'


module Concerns
  module WorkBehavior
    extend ActiveSupport::Concern
    included do
      contains :mdpi_xml, class_name: "XMLFile"

      property :mdpi_date, predicate: RDF::Vocab::EBUCore.dateCreated, multiple: false
    end

    def access_copy
      members_of_quality_level(:access).first
    end

    def mezzanine_copy
      members_of_quality_level(:mezzanine).first
    end

    def members_of_quality_level(quality_level)
      members.select { |member| member.try(:quality_level) == quality_level }
    end

    def assign_properties_from_mdpi_xml
      noko = mdpi_xml.noko.dup
      noko.remove_namespaces!
      self.title += [noko.xpath('/IU/Carrier/Barcode').text]
      self.mdpi_date = DateTime.parse(noko.xpath('/IU/Carrier/Parts/Part/Ingest/Date').text)
    end
  end
end
