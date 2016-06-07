module CurationConcerns
  class WorkPresenter < CurationConcerns::WorkShowPresenter
    delegate :digitized_by_entity, :digitized_by_staff, :mdpi_timestamp, :extraction_workstation, :digitization_comments,
             :original_identifier, :definition, :mdpi_barcode, :unit_of_origin, :original_format, :recording_standard,
             :image_format,
             to: :solr_document


  end
end
