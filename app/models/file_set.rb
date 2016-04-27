require 'IU/models/concerns/file_set_behavior'

class FileSet < ActiveFedora::Base
  include ::CurationConcerns::FileSetBehavior
  include IU::Models::Concerns::FileSetBehavior
end
