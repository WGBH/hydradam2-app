require 'WGBH/models/concerns/file_set_behavior'

module WGBH
  module Models
    class FileSet < ActiveFedora::Base
      include CurationConcerns::FileSetBehavior
      include WGBH::Models::Concerns::FileSetBehavior
    end
  end
end