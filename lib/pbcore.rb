require 'xml_validator'
require 'pry'


module PBCore

  XSD_PATH = File.expand_path('../pbcore/pbcore_2.1.xsd', __FILE__)

  def self.valid?(xml)
    XMLValidator.new(xml: xml, xsd: xsd).valid?
  rescue XMLValidator::XMLValidatorError => e
    false
  end

  def self.xsd
    @xsd ||= File.read(XSD_PATH)
  end
end