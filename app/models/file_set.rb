require 'hydradam/file_set_behavior/has_fits'
require 'hydradam/file_set_behavior/has_ffprobe'

class FileSet < ActiveFedora::Base
  include CurationConcerns::FileSetBehavior
  include HydraDAM::FileSetBehavior::HasFITS
  include HydraDAM::FileSetBehavior::Hasffprobe
end
