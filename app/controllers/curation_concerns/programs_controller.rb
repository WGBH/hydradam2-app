# Generated via
#  `rails generate curation_concerns:work Program`

class CurationConcerns::ProgramsController < ApplicationController
  include CurationConcerns::CurationConcernController
  set_curation_concern_type Program
end
