require 'depends_on'

module HydraDAM
  module WorkBehavior
    module HasMemnon
    extend ActiveSupport::Concern
    included do
    contains :memnon, class_name: "XMLFile"
    end
   end
  end
end
