class FileSet < ActiveFedora::Base
  include ::CurationConcerns::FileSetBehavior
  include Concerns::FileSetBehavior

  class << self
    def indexer
      ::FileSetIndexer
    end
  end
end
