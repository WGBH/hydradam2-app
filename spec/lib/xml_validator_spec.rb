require 'spec_helper'
require 'xml_validator'
require 'fixtures'
require 'pry' # debug only


describe XMLValidator do

  # taken from http://www.w3schools.com/schema/schema_example.asp
  let(:xml_1) { Fixtures.read('xml_validator/ship_order.xml') }
  let(:xsd_1) { Fixtures.read('xml_validator/ship_order.xsd') }

  # from https://msdn.microsoft.com/en-us/library/ms764613(v=vs.85).aspx
  let(:xml_2) { Fixtures.read('xml_validator/books.xml') }

  describe 'xml?' do
    context "when XML is not parseable" do
      subject { described_class.new(xml: "this is not xml").xml? }
      it { is_expected.to eq false }
    end

    context "when XML parses" do
      subject { described_class.new(xml: xml_2).xml? }
      it { is_expected.to eq true }
    end
  end

  describe 'xsd?' do
    context "when XSD is not parseable" do
      subject { described_class.new(xsd: "this is not xsd").xsd? }
      it { is_expected.to eq false }
    end

    context "when XSD is parseable" do
      subject { described_class.new(xsd: xsd_1).xsd? }
      it { is_expected.to eq true }
    end
  end

  describe 'valid?' do

    context "when XML is not parseable" do
      subject { described_class.new(xml: "this is not xml", xsd: xsd_1).valid? }
      it 'raises a XMLValidator::CannotParseXML' do
        expect { subject }.to raise_error XMLValidator::CannotParseXML
      end
    end

    context "when XSD is not parseable" do
      subject { described_class.new(xsd: "this is not xsd").valid? }
      it 'raises a XMLValidator::CannotParseXSD error' do
        expect { subject }.to raise_error XMLValidator::CannotParseXSD
      end
    end

    context "when XML does not validate against XSD" do
      subject { described_class.new(xml: xml_2, xsd: xsd_1).valid? }
      it { is_expected.to eq false}
    end

    context "when XML validates against XSD" do
      subject { described_class.new(xml: xml_1, xsd: xsd_1).valid? }
      # it { is_expected.to eq true }

      it 'returns true' do
        FOO = 1
        expect(subject).to eq true
      end
    end
  end
end