require 'rails_helper'
require 'WGBH/ingest/sip'

describe WGBH::Ingest::SIP do

  let(:sip_with_no_files) { described_class.new }

  let(:sip_with_fits_only) do
    described_class.new.tap do |sip|
      sip.fits_path = 'spec/fixtures/WGBH/fits_batches/fits_batch_valid_1/A060_C001_1114XW_001.R3D.fits.xml'
    end
  end

  describe '#validate!' do
    context 'without any of the required files,' do
      it 'raises an InvalidSIP error' do
        expect { sip_with_no_files.validate! }.to raise_error WGBH::Ingest::Errors::InvalidSIP
      end
    end

    context 'with only a valid FITS xml file,' do
      it 'does not raise an error' do
        expect { sip_with_fits_only.validate! }.to_not raise_error
      end
    end
  end

  describe '#similar_objects' do
    context 'when there are no "similar" objects in Fedora' do
      subject { sip_with_fits_only.similar_objects }
      it { is_expected.to be_empty }
    end

    context 'when there are "similar" objects in Fedora' do

      let(:fake_fedora_search_results) { ['fake thing one', 'fake thing two'] }

      before do
        # Do some mocking of ActiveFedora::Base.where
        similarity_queries = sip_with_fits_only.send(:similarity_queries)
        similarity_queries.each do |similarity_query|
          allow(ActiveFedora::Base).to receive(:where).with(similarity_query).and_return(fake_fedora_search_results)  
        end        
      end

      it 'returns the "similar" objects' do
        expect(sip_with_fits_only.similar_objects).to eq fake_fedora_search_results
      end
    end
  end
end
