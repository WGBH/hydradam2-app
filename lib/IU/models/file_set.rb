require 'IU/models/concerns/file_set_behavior'

module IU
  module Models
    class FileSet < ActiveFedora::Base
      include CurationConcerns::FileSetBehavior
      include IU::Models::Concerns::FileSetBehavior
    end
  end
end