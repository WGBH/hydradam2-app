require 'rails_helper'
require 'fixtures'

describe XMLFile do

  # NOTE: The :requires_fedora tag is added because these tests need Fedora to
  # run. Fedora is needed because XMLFile extends Hydra::PCDM::File and calling
  # #content hits Fedora (somewhere).
  describe '#noko', :requires_fedora do
    context 'when #content does not contain parseable XML' do
      before { subject.content = "i am not xml" }

      it 'raises a Nokogiri::XML::SyntaxError' do
        expect{ subject.noko }.to raise_error Nokogiri::XML::SyntaxError
      end
    end

    context 'when #content contains valid XML' do
      before { subject.content = Fixtures.read('pbcore/valid_pbcore_1.xml') }

      it 'returns a Nokogiri::XML::Document containing the parsed XML content' do
        expect(subject.noko).to be_a Nokogiri::XML::Document
      end
    end
  end
end