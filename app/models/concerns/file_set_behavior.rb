require 'hydradam/file_set_behavior/has_mods'
require 'hydradam/file_set_behavior/has_mdpi'
require 'hydradam/file_set_behavior/has_pod'
require 'hydradam/file_set_behavior/has_ffprobe'

module Concerns
  module FileSetBehavior
    extend ActiveSupport::Concern
    include HydraDAM::FileSetBehavior::HasMods
    include HydraDAM::FileSetBehavior::HasMDPI
    include HydraDAM::FileSetBehavior::HasPod
    include HydraDAM::FileSetBehavior::HasFfprobe
    
   property :date_generated: RDF::Vocab::EBUCore:dateCreated do |index|
      index.as :stored_searchable, :facetable, :stored_sortable
   end
   
   property :file_format: RDF::Vocab::PREMIS:hasFormatName do |index|
      index.as :stored_sortable, :facetable
   end
    
   property :file_format_long_name: RDF::Vocab::EBUCore:hasFileFormat do |index|
      index.as :stored_sortable, :facetable
   end
    
   property :codec_type: RDF::Vocab::EBUCore:hasMedium do |index|
      index.as :stored_sortable, :facetable
   end
    
   property :codec_name: RDF::Vocab::EBUCore:hasCode do |index|
      index.as :stored_sortable, :facetable
   end
    
   property :codec_long_name: RDF::Vocab::EBUCore:codecName 
   #do |index|
   #   index.as :stored_sortable, :facetable
   #end
    
   property :duration: RDF::Vocab::EBUCore:duration do |index|
      index.as :stored_sortable, :facetable
   end 
  end
end
