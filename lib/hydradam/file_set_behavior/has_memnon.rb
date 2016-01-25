require 'depends_on'

module HydraDAM
  module FileSetBehavior
    module Hasmemnon
      extend ActiveSupport::Concern

      included do

        # Ensure class dependencies
        include DependsOn
        depends_on(ActiveFedora::Base)

        # Ensure module dependencies
        include Hydra::Works::FileSetBehavior

        # TODO: replace bogus predicate with legit one.
        directly_contains_one :memnon, through: :files, type: ::RDF::URI('http://example.org/TODO-replace-with-actual-predicate'), class_name: 'XMLFile'

        apply_schema Hydra::Works::Characterization::BaseSchema, Hydra::Works::Characterization::AlreadyThereStrategy

      end

      def assign_properties_from_memnon
        raise MissingFITSFile, "attempting to assign properties from memnon file, but no memnon file present" unless self.memnon
        noko = memnon.noko.dup
        noko.remove_namespaces!
        self.filename = noko.xpath('//memnon/fileinfo/filename').text
      end


      class MissingmemnonFile < StandardError; end
    end
  end
end
