module Fixtures

  def self.base_path
    # Default path is ../../fixtures, relative to this file.
    @base_path ||= File.expand_path('fixtures', File.dirname(File.dirname(__FILE__)))
  end

  def self.base_path=(base_path)
    @base_path = base_path
  end

  def self.full_path(relative_path)
    File.join(Fixtures.base_path, relative_path)
  end

  def self.open(relative_path, opts={})
    filename = full_path(relative_path)
    raise NotFound, "Fixture file #{filename} does not exist" unless File.exists?(filename)
    File.open(filename, 'r')
  end

  def self.read(relative_path)
    open(relative_path).read
  end

  class NotFound < StandardError; end
end