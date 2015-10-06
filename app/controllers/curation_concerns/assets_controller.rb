# Generated via
#  `rails generate curation_concerns:work Asset`

class CurationConcerns::AssetsController < ApplicationController
  include CurationConcerns::CurationConcernController
  set_curation_concern_type Asset
end
