require 'rails_helper'
require 'WGBH/ingest/sip'

describe WGBH::Ingest::SIP do

  # Setup a test admin user that will persist between tests.
  before(:all) do
    @test_admin_user = User.new(
      email: 'test.admin@hydradam.org',
      guest: false,
      password: 'password'
    )
  end


  let(:sip_with_no_files) { described_class.new(depositor: @test_admin_user) }

  let(:sip_with_fits_only) do
    described_class.new(depositor: @test_admin_user).tap do |sip|
      sip.fits_path = 'spec/fixtures/WGBH/fits_batches/fits_batch_valid_1/A060_C001_1114XW_001.R3D.fits.xml'
    end
  end

  describe '#validate!' do
    context 'without any of the required files,' do
      it 'raises an InvalidSIP error' do
        expect { sip_with_no_files.validate! }.to raise_error WGBH::Ingest::Error::InvalidSIP
      end
    end

    context 'with only a valid FITS xml file,' do
      it 'does not raise an error' do
        expect { sip_with_fits_only.validate! }.to_not raise_error
      end
    end
  end


  describe '#ingested_objects' do
    context 'before calling #run!' do
      it 'returns an empty array' do
        expect(sip_with_fits_only.ingested_objects).to be_empty
      end
    end

    context 'after calling #ingest!' do

      before { 
        sip_with_fits_only.ingest!
      }

      after do
        sip_with_fits_only.ingested_objects.each { |obj| obj.delete }
      end

      # helper method - returns true if all of `objects' inherit from
      #   `class_or_module'
      def each_is_a?(objects, class_or_module)
        objects.map { |obj| obj.is_a? class_or_module }.all?
      end

      # helper method - returns true if all of `objects' have been persisted.
      def each_has_been_persisted?(objects)
        objects.map { |obj| obj.persisted? }.all?
      end

      it 'returns the number of objects in the SIP that were ingested' do
        expect(sip_with_fits_only.ingested_objects.count).to eq 1
      end

      it 'returns a list of FileSet objects' do
        expect(each_is_a?(sip_with_fits_only.ingested_objects, WGBH::Models::FileSet)).to eq true
      end

      it 'returns a list of saved objects' do
        expect(each_has_been_persisted?(sip_with_fits_only.ingested_objects)).to eq true
      end

      it 'returns object that have metadata from the FITS xml files' do
        expect(sip_with_fits_only.ingested_objects.first.original_checksum).to eq ['72b25107b04ea51ec827053810cc19a8']
      end
    end
  end


  describe '#duplicate_objects_found' do
    context 'when there are no duplicate objects in Fedora,' do
      it 'is empty' do
        expect(sip_with_fits_only.duplicate_objects_found).to be_empty
      end
    end

    context 'when there are duplicate objects in Fedora' do

      before { sip_with_fits_only.ingest! }
      
      after do
        sip_with_fits_only.ingested_objects.each { |obj| obj.delete }
      end

      it 'returns the duplicate objects' do
        expect(sip_with_fits_only.duplicate_objects_found.count).to be >= 1
      end
    end
  end
end
