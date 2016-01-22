require 'depends_on'

module HydraDAM
  module FileSetBehavior
    module HasFITS
      extend ActiveSupport::Concern

      included do

        # Ensure class dependencies
        include DependsOn
        depends_on(ActiveFedora::Base)

        # Ensure module dependencies
        include Hydra::Works::FileSetBehavior

        # TODO: replace bogus predicate with legit one.
        directly_contains_one :fits, through: :files, type: ::RDF::URI('http://example.org/TODO-replace-with-actual-predicate'), class_name: 'XMLFile'

        apply_schema Hydra::Works::Characterization::BaseSchema, Hydra::Works::Characterization::AlreadyThereStrategy

      end

      def assign_properties_from_fits
        raise MissingFITSFile, "attempting to assign properties from FITS file, but no FITS file present" unless self.fits
        noko = fits.noko.dup
        noko.remove_namespaces!
        self.filename = noko.xpath('//fits/fileinfo/filename').text
      end


      class MissingFITSFile < StandardError; end
    end
  end
end