class FileSetIndexer < CurationConcerns::FileSetIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('filename')] = object.filename

      searchable_file_format = Solrizer.solr_name('file_format', :stored_searchable)
      solr_doc[searchable_file_format] ||= []
      solr_doc[searchable_file_format] += object.file_format

      facetable_file_format = Solrizer.solr_name('file_format', :facetable)
      solr_doc[facetable_file_format] ||= []
      solr_doc[facetable_file_format] += object.file_format
    end
  end
end
