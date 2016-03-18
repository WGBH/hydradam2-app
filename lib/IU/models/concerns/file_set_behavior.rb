require 'hydradam/file_set_behavior/has_ffprobe'

module IU
  module Models
    module Concerns
      module FileSetBehavior
        extend ActiveSupport::Concern
        include HydraDAM::FileSetBehavior::HasFfprobe
      end
    end
  end
end