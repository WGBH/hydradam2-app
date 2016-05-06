require 'IU/models/concerns/file_set_behavior'

class FileSet < ActiveFedora::Base
  include IU::Models::Concerns::FileSetBehavior


  class << self
    def indexer
      ::FileSetIndexer
    end
  end
end
