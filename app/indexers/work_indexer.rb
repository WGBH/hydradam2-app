class WorkIndexer < CurationConcerns::WorkIndexer

  def generate_solr_document
    super.tap do |solr_doc|
      # Index the ingest dates as integer timestamps so we can facet on it.
      # '_isim' suffix implies integer, stored, indexed
      solr_doc['mdpi_timestamp_isi'] = object.mdpi_date.to_i
    end
  end
end
