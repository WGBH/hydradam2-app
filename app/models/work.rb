# Generated via
#  `rails generate curation_concerns:work Work`
require 'IU/models/concerns/work_behavior'

class Work < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  include ::IU::Models::Concerns::WorkBehavior
  # validates :title, presence: { message: 'Your work must have a title.' }
end
