module WGBH
  module Ingest
    class SIP

      attr_accessor :fits_path

      attr_reader :errors

      # - allows setting of filepaths
      # - creates Fedora objects from files
      # Public api
      #   - #ingest!
      #   - #valid?
      #   - #validate!

      def validate!
        raise Errors::InvalidSIP unless File.exists? fits_path.to_s
      end

      def similar_objects
        similar_objects = similarity_queries.map do |query|
          ActiveFedora::Base.where(query)
        end.flatten
      end

      private

      def similarity_queries
        queries = []
        queries << {original_checksum: fits_checksum}
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

    class SIPBatch
      # Logic
      #   - traverses a directory identifying files that belong in a SIP
      #   - instantiates SIPs and assigns filepaths
      #   - invokes SIP's ingest method
      #   - writes to log
      # Required class variables
      #   - @sip_class
      # Required instance variables
      #   - @path
      # Public API
      #   - #ingest!
    end


    # Custom errors
    module Errors
      class InvalidSIP < StandardError; end
    end
  end
end