# FIXME: better configure library includes
require './lib/hydradam/preingest/attribute_ingester.rb'

module HydraDAM
  module Preingest
    module IU
      class Yaml
        def initialize(preingest_file)
          @preingest_file = preingest_file
          parse
        end
        attr_reader :preingest_file
        attr_reader :work_attributes, :file_set_attributes, :source_metadata, :file_sets, :sources

        def resource_class
          Work
        end

        def source_metadata
          nil
        end

        def parse
          @work_attributes = {}
          @file_set_attributes = {}
          @source_metadata = nil
          @file_sets = []
          @sources = []
        end
      end
    end
  end
end
