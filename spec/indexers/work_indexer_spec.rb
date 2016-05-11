require 'rails_helper'

describe WorkIndexer do

  describe '#generate_solr_document' do

    let(:fake_work) { Work.new }

    subject { WorkIndexer.new(fake_work).generate_solr_document }

    it 'indexes a DateTime object as a integer timestamp' do
      test_date = DateTime.now
      allow(fake_work).to receive(:date).and_return(test_date)
      expect(subject['ingest_timestamp_sim']).to eq test_date.to_time.to_i
    end
  end
end
