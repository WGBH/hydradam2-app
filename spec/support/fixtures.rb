module Fixtures

  def fixture(relative_path)
    fixture_file = File.join(Fixtures.path, relative_path)
    raise NotFound, "Fixture file #{fixture_file} does not exist" unless File.exists?(fixture_file)
    File.read(fixture_file)
  end

  def self.path
    # Default path is ../../fixtures, relative to this file.
    @path ||= File.expand_path('fixtures', File.dirname(File.dirname(__FILE__)))
  end

  def self.path=(path)
    @path = path
  end

  class NotFound < StandardError; end
end