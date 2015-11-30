require 'hydra/pcdm/models/file'

class XMLFile < Hydra::PCDM::File
  def noko
    @noko ||= Nokogiri::XML(content) do |config|
      config.strict.nonet.noblanks
    end
  end
end