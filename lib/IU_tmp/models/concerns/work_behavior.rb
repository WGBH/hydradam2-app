require 'hydradam/file_set_behavior/has_ffprobe'

module IU
  module Models
    module Concerns
      module WorkBehavior
        extend ActiveSupport::Concern
        included do
          contains :mdpi_xml, class_name: "XMLFile"
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
      end
    end
  end
end