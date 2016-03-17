require 'rails_helper'
require 'IU/ingest/sip'

describe IU::Ingest::SIP do

  # Setup a test admin user that will persist between tests.
  # before(:all) do
  #   @test_admin_user = User.new(
  #     email: 'test.admin@hydradam.org',
  #     guest: false,
  #     password: 'password'
  #   )
  # end

  let(:valid_opts) do
    {
      path: 'spec/fixtures/IU/MDPI-SIP-package',
      depositor: User.new(
        email: 'test.admin@hydradam.org',
        guest: false,
        password: 'password'
      )
    }
  end

  let(:sip) { IU::Ingest::SIP.new(valid_opts) }

  describe '#initialize' do
    context 'when the :path is not a valid directory,' do
      let(:sip_wth_invalid_path) do
        opts_with_invalid_path = valid_opts.dup.tap { |opts| opts[:path] = 'not a valid directory' }
        IU::Ingest::SIP.new(opts_with_invalid_path)
      end

      it 'raises an InvalidPath error' do
        expect { sip_wth_invalid_path }.to raise_error IU::Ingest::Error::InvalidPath
      end
    end
  end

  describe '#ingested_objects' do
    context 'before calling #run!' do
      it 'returns an empty array' do
        expect(sip.ingested_objects).to be_empty
      end
    end

    context 'after calling #ingest!' do

      # Run an ingest before each of these examles.
      before { sip.ingest! }

      # Clean up ingested objects after each of these examples.
      after do
        sip.ingested_objects.each { |obj| obj.delete }
      end

      # helper method - returns true if all of `objects' have been persisted.
      def each_has_been_persisted?(objects)
        objects.map { |obj| obj.persisted? }.all?
      end

      it 'returns a non-empty list of saved objects' do
        expect(sip.ingested_objects).to_not be_empty
        expect(each_has_been_persisted?(sip.ingested_objects)).to eq true
      end


    end

  end




  #     it 'returns the number of objects in the SIP that were ingested' do
  #       expect(sip_with_fits_only.ingested_objects.count).to eq 1
  #     end

  #     it 'returns a list of FileSet objects' do
  #       expect(each_is_a?(sip_with_fits_only.ingested_objects, FileSet)).to eq true
  #     end

  #     it 'returns a list of saved objects' do
  #       expect(each_has_been_persisted?(sip_with_fits_only.ingested_objects)).to eq true
  #     end

  #     it 'returns object that have metadata from the FITS xml files' do
  #       expect(sip_with_fits_only.ingested_objects.first.original_checksum).to eq ['72b25107b04ea51ec827053810cc19a8']
  #     end
  #   end
  # end


  # describe '#duplicate_objects_found' do
  #   context 'when there are no duplicate objects in Fedora,' do
  #     it 'is empty' do
  #       expect(sip_with_fits_only.duplicate_objects_found).to be_empty
  #     end
  #   end

  #   context 'when there are duplicate objects in Fedora' do

  #     before { sip_with_fits_only.ingest! }
      
  #     after do
  #       sip_with_fits_only.ingested_objects.each { |obj| obj.delete }
  #     end

  #     it 'returns the duplicate objects' do
  #       expect(sip_with_fits_only.duplicate_objects_found.count).to be >= 1
  #     end
  #   end
  # end
end