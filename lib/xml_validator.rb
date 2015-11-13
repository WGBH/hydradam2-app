require 'nokogiri'

class XMLValidator

  attr_accessor :xml, :xsd

  def initialize(opts={})
    @xml = opts.delete(:xml)
    @xsd = opts.delete(:xsd)
  end

  def xml?
    # binding.pry
    !!(noko_xml rescue nil)
  end

  def xsd?
    # binding.pry
    !!(noko_xsd rescue nil)
  end

  def valid?
    validate.empty?
  end

  private

  def validate
    noko_xsd.validate(noko_xml)
  end

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

  class CannotParseXML < StandardError; end
  class CannotParseXSD < StandardError; end
end