require 'WGBH/models/concerns/file_set_behavior'

class FileSet < ActiveFedora::Base
  include WGBH::Models::Concerns::FileSetBehavior
end
