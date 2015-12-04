require 'pbcore'

class Asset < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata

  contains :pbcore, class_name: "XMLFile"

  # TODO: Review these predicates to see if we're using them appropriately.
  # TODO: wgbh-mla.org doesn't exist yet.
  property :department, predicate: ::RDF::Vocab::EBUCore.hasDepartment do |index|
    index.as :stored_searchable
  end

  property :artesia_uoi_id, predicate: 'http://wgbh-mla.org/schema#hasArtesiaUOI_ID' do |index|
    index.as :stored_searchable
  end

  property :file_size, predicate: ::RDF::Vocab::EBUCore.fileSize do |index|
    index.as :stored_searchable
  end

  property :lto_path, predicate: ::RDF::Vocab::PREMIS.hasOriginalName do |index|
    index.as :stored_searchable
  end

  property :filename, predicate: ::RDF::Vocab::EBUCore.filename do |index|
    index.as :stored_searchable
  end

  property :dimension_annotation, predicate: 'http://wgbh-mla.org/schema#hasDimensionAnnotation' do |index|
    index.as :stored_searchable
  end

  property :description, predicate: ::RDF::Vocab::DC11.description do |index|
    index.as :stored_searchable
  end

  # validation rules
  validates :title, presence: { message: 'Your work must have a title.' }


  def assign_properties_from_pbcore_file
    return if pbcore.content.nil?
    raise InvalidPBCore unless PBCore.valid?(pbcore.content)

    # Remove namespaces to avoid having to specify namespace per xpath query.
    pbcore.noko.remove_namespaces!

    self.title = pbcore_literals_from_xpath("//pbcoreTitle/text()")
    #  TODO: self.department = pbcore_literals_from_xpath()
    self.artesia_uoi_id = pbcore_literals_from_xpath("//pbcoreIdentifier[@source='UOI_ID']/text()")
    self.file_size = pbcore_literals_from_xpath("//instantiationFileSize/text()")
    self.lto_path = pbcore_literals_from_xpath("//instantiationLocation/text()")
    self.filename = pbcore_literals_from_xpath("//instantiationAnnotation[@annotationType='File Name']/text()")
    self.dimension_annotation = pbcore_literals_from_xpath("//pbcoreAnnotation[@annotationType='Movie Quality']/text()")
    self.description = pbcore_literals_from_xpath("//pbcoreDescription[@descriptionType='Description']/text()")
    
  end


  private

  def pbcore_literals_from_xpath(xpath)
    pbcore.noko.xpath(xpath).map(&:to_s)
  end

  class AssetError < StandardError; end
  class InvalidPBCore < AssetError; end

end