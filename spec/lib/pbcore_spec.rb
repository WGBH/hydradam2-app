require 'pbcore'
require 'fixtures'

describe PBCore do
  describe '.valid?' do

    let(:valid_pbcore) { Fixtures.read('pbcore/valid_pbcore_1.xml') }
    let(:not_pbcore) { Fixtures.read('xml_validator/books.xml') }

    context "when given valid pbcore" do
      subject { PBCore.valid? valid_pbcore }
      it { is_expected.to eq true }
    end

    context "when given invalid pbcore" do
      subject { PBCore.valid? not_pbcore }
      it { is_expected.to eq false }
    end
  end
end