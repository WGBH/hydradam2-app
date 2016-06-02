# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  # Adds CurationConcerns behaviors to the SolrDocument.
  include CurationConcerns::SolrDocumentBehavior


  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # Do content negotiation for AF models. 

  use_extension( Hydra::ContentNegotiation )

  def filename
    File.basename(fetch(Solrizer.solr_name(:filename, :stored_searchable), ['Unknown']).first)
  end

  def file_size
    fetch(Solrizer.solr_name(:file_size, Solrizer::Descriptor.new(:long, :stored, :indexed)), [])
  end

  def quality_level
    fetch(Solrizer.solr_name(:quality_level, :stored_searchable), [])
  end

  def mdpi_timestamp
    fetch('mdpi_timestamp_isi', [])
  end

  def original_checksum
    fetch(Solrizer.solr_name(:original_checksum, :symbol), [])
  end

  def date_generated
    fetch(Solrizer.solr_name(:original_checksum, :stored_searchable), [])
  end

  def file_format_long_name
    fetch(Solrizer.solr_name(:file_format_long_name, :symbol), [])
  end

  def codec_type
    fetch(Solrizer.solr_name(:codec_type, :stored_searchable), [])
  end

  def codec_name
    fetch(Solrizer.solr_name(:codec_name, :stored_searchable), [])
  end

  def codec_long_name
    fetch(Solrizer.solr_name(:codec_long_name, :stored_searchable), [])
  end

  def duration
    fetch(Solrizer.solr_name(:duration, :stored_searchable), [])
  end

  def bit_rate
    fetch(Solrizer.solr_name(:bit_rate, :stored_searchable), [])
  end

  def unit_of_origin
    fetch(Solrizer.solr_name(:unit_of_origin, :stored_searchable), [])
  end

  def mdpi_barcode
    fetch(Solrizer.solr_name(:mdpi_barcode, :stored_searchable), [])
  end

  def recording_standard
    fetch(Solrizer.solr_name(:recording_standard, :stored_searchable), [])
  end

  def original_format
    fetch(Solrizer.solr_name(:original_format, :stored_searchable), [])
  end


end
