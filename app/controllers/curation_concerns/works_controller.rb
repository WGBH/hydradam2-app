# Generated via
#  `rails generate curation_concerns:work Work`

class CurationConcerns::WorksController < ApplicationController
  include CurationConcerns::CurationConcernController
  self.curation_concern_type = Work
end
