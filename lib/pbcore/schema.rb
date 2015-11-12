module PBCore
  module Schema

    PATH = File.expand_path('pbcore_2.1.xsd', File.dirname(__FILE__))
    
    def self.noko
      @noko ||= Nokogiri::XML::Schema(raw)
    end

    def self.raw
      @raw ||= File.read(PATH)
    end

    def self.validate(xml)
      noko.validate(Nokogiri::XML(xml))
    end

    def self.valid?(xml)
      validate(xml).empty?
    end
  end
end