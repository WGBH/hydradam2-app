require 'pbcore'

describe PBCore do
  describe '.valid?' do

    let(:valid_pbcore_xml) { fixture('pbcore/valid_pbcore_1.xml') }

    it 'returns true when given valid pbcore xml' do
      expect(PBCore.valid?(valid_pbcore_xml)).to eq true
    end
  end
end