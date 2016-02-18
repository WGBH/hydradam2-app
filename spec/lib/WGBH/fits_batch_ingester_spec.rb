require 'spec_helper'
require 'wgbh/fits_batch_ingester'

describe WGBH::FITSBatchIngester do

  before(:all) do
    # Setup a test admin user that will persist between tests.
    @test_admin_user = User.new(
      email: 'test.admin@hydradam.org',
      guest: false,
      password: 'password'
    )
  end

  describe '#logger' do
    it 'returns a Logger object' do
      expect(subject.logger).to be_a Logger
    end
  end

  describe '#ingested_objects' do
    context 'before calling #run!' do
      it 'returns an empty array' do
        ingester = WGBH::FITSBatchIngester.new
        expect(ingester.ingested_objects).to be_empty
      end
    end

    context 'after calling #run!' do

      before(:all) do
        # Create an ingester for use with all examples in this context, and run
        # an ingest.
        @ingester = WGBH::FITSBatchIngester.new(
          path: './spec/fixtures/WGBH/fits_batches/fits_batch_valid_1',
          depositor: @test_admin_user
        )
        @ingester.run!
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

      it 'returns the same number of objects as files in the batch' do
        expect(@ingester.ingested_objects.count).to eq 2
      end

      it 'returns a list of FileSet objects' do
        expect(each_is_a?(@ingester.ingested_objects, FileSet)).to eq true
      end

      it 'returns a list of saved objects' do
        expect(each_has_been_persisted?(@ingester.ingested_objects)).to eq true
      end
    end
  end
end