module CurationConcerns
  class WorkPresenter < CurationConcerns::WorkShowPresenter
    delegate :mdpi_timestamp, to: :solr_document


  end
end
