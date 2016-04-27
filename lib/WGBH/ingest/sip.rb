require 'WGBH/models/file_set'

module WGBH
  module Ingest
    class SIP
      # This should be WGBH::Models::FileSet, or a descendent thereof.
      FILE_SET_CLASS = WGBH::Models::FileSet

      attr_accessor :fits_path, :depositor

      attr_reader :ingested_objects

      def initialize(opts={})
        raise ArgumentError, "Option :depositor is required" unless opts.key? :depositor
        @depositor = opts.delete(:depositor)
        @ingested_objects = []
      end

      def validate!
        raise Error::InvalidSIP unless File.exists? fits_path.to_s
      end

      def duplicate_objects_found
        equivalence_queries.map do |query|
          ActiveFedora::Base.where(query)
        end.flatten
      end

      def ingest!

        raise Error::DuplicateObjectFound unless duplicate_objects_found.empty?

        # TODO: handle cases where we're not dealing with just a FITS file.
        #  Other options include a PBCore file, and a EXIF file.
        file_set = FILE_SET_CLASS.new
        file_set.apply_depositor_metadata depositor
        file_set.save!
        file = File.open(fits_path)
        Hydra::Works::AddFileToFileSet.call(file_set, file, :fits)
        file.close
        file_set.assign_properties_from_fits
        file_set.save!
        @ingested_objects << file_set
      end

      private

      def equivalence_queries
        queries = []
        # TODO: Avoid having to specify the dynamic suffix _tesim here.
        # Dynamic suffixes are subject to change via how they are indexed.
        queries << {original_checksum_tesim: fits_checksum}
      end

      def fits_checksum
        fits_noko.xpath('//fits/fileinfo/md5checksum').text
      end

      def fits_noko
        @fits_noko ||= Nokogiri::XML(File.read(fits_path))
        # TODO: Is blindly removing namespaces ok?
        @fits_noko.remove_namespaces!
        @fits_noko
      end

    end

    # Custom errors
    module Error
      class InvalidSIP < StandardError; end
      class DuplicateObjectFound < StandardError; end
    end
  end
end