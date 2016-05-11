require 'rails_helper'

describe Work do
  describe '#do_fixity_check' do
    it 'calls #do_md5_checksum' do
      expect(subject).to receive(:do_md5_checksum).exactly(1).times
      subject.do_fixity_check
    end
  end
end

describe '#check for rfc3339 format ' do
    context 'when the date is not of rfc3339 format' do
      it 'checks for iso8601format ' do
        expect { sip_with_invalid_date }.to eq ['mm/dd/yyyy hh:mm:ss']
      end
    end
end
  
describe '#check for iso8601 format ' do
    context 'when the date is not of iso8601 format' do
      it 'returns invalid date ' do
        expect { sip_with_invalid_date }.to eq ['yyyy-mm-dd']
      end
    end
end
  
