require 'rails_helper'

describe Work do
  describe '#do_fixity_check' do
    it 'calls #do_md5_checksum' do
      expect(subject).to receive(:do_md5_checksum).exactly(1).times
      subject.do_fixity_check
    end
  end
end  
