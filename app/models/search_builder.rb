# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  self.default_processor_chain += [:add_advanced_parse_q_to_solr, :add_advanced_search_to_solr]
  include Hydra::AccessControlsEnforcement
  include CurationConcerns::SearchFilters


  def filter_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << '(' + (work_clauses + collection_clauses + file_set_clauses).join(' OR ') + ')'
  end
  
  def file_set_clauses
    [ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::FileSet.to_class_uri)]
  end
end
