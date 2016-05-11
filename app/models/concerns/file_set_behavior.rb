require 'hydradam/file_set_behavior/has_ffprobe'

module Concerns
  module FileSetBehavior
    extend ActiveSupport::Concern
    include HydraDAM::FileSetBehavior::HasFfprobe

    attr_accessor :quality_level
  end
end
