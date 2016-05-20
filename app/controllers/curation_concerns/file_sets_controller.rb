module CurationConcerns
  class FileSetsController < ApplicationController
    include CurationConcerns::FileSetsControllerBehavior
    include HydraDAM::StorageControllerBehavior
  end
end
