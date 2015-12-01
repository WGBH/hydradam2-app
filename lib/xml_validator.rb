require 'nokogiri'

class XMLValidator

  attr_accessor :xml, :xsd

  def initialize(opts={})
    @xml = opts.delete(:xml)
    @xsd = opts.delete(:xsd)
  end

  def xml?
    !!(noko_xml rescue nil)
  end

  def xsd?
    !!(noko_xsd rescue nil)
  end

  def valid?
    validate.empty?
  end

  def validate
    noko_xsd.validate(noko_xml)
  end

  private

  def noko_xml
    @noko_xml ||= Nokogiri::XML(xml) do |config|
      config.strict.nonet
    end
  rescue
    raise CannotParseXML
  end

  def noko_xsd
    @noko_xsd ||= Nokogiri::XML::Schema(xsd)
  rescue
    raise CannotParseXSD
  end

  class XMLValidatorError < StandardError; end
  class CannotParseXML < XMLValidatorError; end
  class CannotParseXSD < XMLValidatorError; end
end