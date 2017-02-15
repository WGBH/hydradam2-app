# FIXME: better configure library includes
require './lib/hydradam/preingest/attribute_ingester.rb'

module HydraDAM
  module Preingest
    module IU
      class Yaml
        def initialize(preingest_file)
          @preingest_file = preingest_file
          @yaml = File.open(preingest_file) { |f| Psych.load(f) }
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
          @work_attributes = @yaml[:work_attributes]
          @work_attributes.each do |source, attributes_set|
            @work_attributes[source] = HydraDAM::Preingest::AttributeIngester.new(@preingest_file, attributes_set, factory: resource_class).raw_attributes
          end
          @file_set_attributes = @yaml[:file_set_attributes]
          @file_set_attributes.each do |source, attributes_set|
            @file_set_attributes[source] = HydraDAM::Preingest::AttributeIngester.new(@preingest_file, attributes_set, factory: FileSet).raw_attributes
          end
          @source_metadata = @yaml[:source_metadata]
          @file_sets = @yaml[:file_sets]
          @file_sets.select { |fs| fs[:attributes].present? }.each do |file_set|
            file_set[:attributes] = HydraDAM::Preingest::AttributeIngester.new(@preingest_file, file_set[:attributes], factory: FileSet).raw_attributes
          end
          @sources = @yaml[:sources]
        end
      end
    end
  end
end
