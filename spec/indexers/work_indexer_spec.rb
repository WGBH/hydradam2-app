require 'rails_helper'

describe WorkIndexer do

  describe '#generate_solr_document' do

    let(:sample_work) do
      Work.new.tap do |work|
        work.mdpi_date = DateTime.now
      end
    end

    subject { WorkIndexer.new(sample_work) }

    it 'indexes a DateTime object as a integer timestamp' do
      expect(subject.generate_solr_document['mdpi_timestamp_isi']).to eq sample_work.mdpi_date.strftime('%Y%m%d').to_i
    end
  end
end
