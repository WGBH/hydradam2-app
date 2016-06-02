module CurationConcerns
  class WorkPresenter < CurationConcerns::WorkShowPresenter
    delegate :mdpi_timestamp, :mdpi_barcode, :original_format, :recording_standard,  to: :solr_document


  end
end
