require 'hydradam/file_set_behavior/has_fits'

class FileSet < ActiveFedora::Base
  include CurationConcerns::FileSetBehavior
  include HydraDAM::FileSetBehavior::HasFITS
end