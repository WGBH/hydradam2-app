require 'hydradam/file_set_behavior/has_fits'

module WGBH
  module Models
    module Concerns
      module FileSetBehavior
        extend ActiveSupport::Concern
        include HydraDAM::FileSetBehavior::HasFITS
      end
    end
  end
end