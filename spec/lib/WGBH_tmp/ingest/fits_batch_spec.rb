require 'rails_helper'
require 'WGBH/ingest/fits_batch'

describe WGBH::Ingest::FITSBatch do

  before(:all) do
    # Setup a test admin user that will persist between tests.
    @test_admin_user = User.new(
      email: 'test.admin@hydradam.org',
      guest: false,
      password: 'password'
    )
  end

  let(:fits_batch) do
    described_class.new depositor: @test_admin_user, path: 'spec/fixtures/WGBH/fits_batches/fits_batch_valid_1'
  end

  describe '#logger' do
    it 'returns a Logger object' do
      expect(subject.logger).to be_a Logger
    end
  end

  describe '#ingest' do
    it 'appends SIP objects to the #sips array for every FITS file found' do
      expect { fits_batch.ingest! }.to change { fits_batch.sips.count }.from(0).to(2)
    end

    after do
      # Cleanup what was ingested within the examples.
      fits_batch.sips.each do |sip|
        sip.ingested_objects.each { |obj| obj.delete }
      end
    end
  end

  describe '#sips' do
    context 'before calling #ingest!' do
      it 'returns an empty array' do
        expect(fits_batch.sips).to be_empty
      end
    end
  end
end