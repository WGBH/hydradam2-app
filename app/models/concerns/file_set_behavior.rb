require 'hydradam/file_set_behavior/has_mods'
require 'hydradam/file_set_behavior/has_mdpi'
require 'hydradam/file_set_behavior/has_pod'
require 'hydradam/file_set_behavior/has_ffprobe'

module Concerns
  module FileSetBehavior
    extend ActiveSupport::Concern
    
    included do    

     property :date_generated, predicate: RDF::Vocab::EBUCore.dateCreated do |index|
        index.as :stored_searchable, :facetable, :stored_sortable
     end
     
     property :file_format, predicate: RDF::Vocab::PREMIS.hasFormatName do |index|
        index.as :stored_sortable, :facetable
     end
      
     property :file_format_long_name, predicate: RDF::Vocab::EBUCore.hasFileFormat do |index|
        index.as :stored_sortable, :facetable
     end
      
     property :codec_type, predicate: RDF::Vocab::EBUCore.hasMedium do |index|
        index.as :stored_sortable, :facetable
     end
      
     property :codec_name, predicate: RDF::Vocab::EBUCore.hasCodec do |index|
        index.as :stored_sortable, :facetable
     end
      
     property :codec_long_name, predicate: RDF::Vocab::EBUCore.codecName 
     #do |index|
     #   index.as :stored_sortable, :facetable
     #end
      
     property :duration, predicate: RDF::Vocab::EBUCore.duration do |index|
        index.as :stored_sortable, :facetable
     end 
      
     property :bit_rate, predicate: RDF::Vocab::EBUCore.bitRate 
     
     property :file_name, predicate: RDF::Vocab::EBUCore.filename do |index|
        index.as :stored_searchable
     end 
      
     property :file_size, predicate: RDF::Vocab::EBUCore.fileSize 
      
     property :identifier, predicate: RDF::Vocab::EBUCore.identifier do |index|
        index.as :stored_searchable
     end 
      
     property :unit_of_origin, predicate: RDF::Vocab::EBUCore.comments do |index|
        index.as :stored_searchable, :facetable, :stored_sortable
     end 
     
     property :part, predicate: RDF::Vocab::EBUCore.partNumber
      
     property :sample_rate, predicate: RDF::Vocab::EBUCore.sampleRate 
      
     property :video_width, predicate: RDF::Vocab::EBUCore.width 
      
     property :video_height, predicate: RDF::Vocab::EBUCore.height
      
     property :md5_checksum, predicate: RDF::Vocab::NFO.hashValue do |index|
        index.as :stored_searchable
     end 

    end
  end
end
