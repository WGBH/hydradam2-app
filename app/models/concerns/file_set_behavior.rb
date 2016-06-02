require 'hydradam/file_set_behavior/has_mods'
require 'hydradam/file_set_behavior/has_mdpi'
require 'hydradam/file_set_behavior/has_pod'
require 'hydradam/file_set_behavior/has_ffprobe'

module Concerns
  module FileSetBehavior
    extend ActiveSupport::Concern
    include HydraDAM::FileSetBehavior::HasMods
    include HydraDAM::FileSetBehavior::HasMDPI
    include HydraDAM::FileSetBehavior::HasPod
    include HydraDAM::FileSetBehavior::HasFfprobe
  end
end
