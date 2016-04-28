class FileSetIndexer < CurationConcerns::FileSetIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('filename')] = object.filename
    end
  end
end
