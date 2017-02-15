require 'rails_helper'

describe SearchBuilder do
  subject do
    # Method signature for CurationConcerns::SearchBuilder is the same as 
    # Blacklight::SearchBuilder.
    # see https://github.com/projectblacklight/blacklight/blob/v5.17.1/lib/blacklight/search_builder.rb#L17
    SearchBuilder.new(CatalogController)
  end

  skip '#filter_models' do # FIXME: commented out, broken with curation_concerns upgrade
    it 'includes #file_set_clauses as one of the values in the returned array, which represents the :fq of the solr parameters' do
      # We can just grab the first one, since we're starting with nothing, by
      # passing an empty hash.
      fq = subject.filter_models({}).first
      expect(fq).to include subject.file_set_clauses.first
    end
  end
end
