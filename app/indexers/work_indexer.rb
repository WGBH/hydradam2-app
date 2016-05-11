class WorkIndexer < CurationConcerns::WorkIndexer

  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('ingest_timestamp', :facetable)] = object.date.to_time.to_i
    end
  end
end
