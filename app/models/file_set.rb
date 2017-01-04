class FileSet < ActiveFedora::Base
  include ::CurationConcerns::FileSetBehavior

  class << self
    def indexer
      ::FileSetIndexer
    end
  end
end
