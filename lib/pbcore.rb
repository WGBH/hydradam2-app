require 'nokogiri'
require_relative 'pbcore/schema'

module PBCore
  def self.valid?(xml)
    Schema.valid?(xml)
  end
end