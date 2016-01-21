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
      end
    end
  end
end