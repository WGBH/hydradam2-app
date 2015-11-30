require 'pbcore'

# Generated via
#  `rails generate curation_concerns:work Asset`
class Asset < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata

  validates :title, presence: { message: 'Your work must have a title.' }

  contains :pbcore, class_name: "XMLFile"

  def assign_properties_from_pbcore_file
    return if pbcore.content.nil?
    raise InvalidPBCore unless PBCore.valid?(pbcore.content)
    pbcore.noko.remove_namespaces!
    self.title = pbcore.noko.xpath("//pbcoreTitle/text()").map(&:to_s)
    self.title << "other junk"
  end

  class AssetError < StandardError; end
  class InvalidPBCore < AssetError; end

end
