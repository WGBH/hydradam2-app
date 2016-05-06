class FileSet < ActiveFedora::Base
  include Concerns::FileSetBehavior

  class << self
    def indexer
      ::FileSetIndexer
    end
  end
end
