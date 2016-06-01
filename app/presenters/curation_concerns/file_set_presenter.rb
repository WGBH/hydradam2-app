module CurationConcerns
  class FileSetPresenter
    include ModelProxy
    include PresentsAttributes
    attr_accessor :solr_document, :current_ability

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    def initialize(solr_document, current_ability)
      @solr_document = solr_document
      @current_ability = current_ability
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :image?, :video?,
             :audio?, :pdf?, :office_document?, :representative_id, :to_s, to: :solr_document

    # Methods used by blacklight helpers
    delegate :has?, :first, :fetch, to: :solr_document

    # Metadata Methods
    delegate :title, :description, :creator, :contributor, :subject, :publisher,
             :language, :date_uploaded, :rights,
             :embargo_release_date, :lease_expiration_date,
             :depositor, :tags, :title_or_label, to: :solr_document

    delegate :filename, :file_format, :file_format_long_name, :file_size, :original_checksum, :quality_level,
             :date_generated, :codec_type, :codec_name, :codec_long_name, :duration, :mdpi_timestamp,
             :bit_rate, :unit_of_origin, :unit_of_origin_statement, :alt_unit_origin_statement,
             to: :solr_document


    def page_title
      Array.wrap(solr_document['label_tesim']).first
    end

    def link_name
      current_ability.can?(:read, id) ? Array.wrap(solr_document['label_tesim']).first : 'File'
    end
  end
end
