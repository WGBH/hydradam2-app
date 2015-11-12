require_relative 'fixtures'

RSpec.configure do |config|
  config.include Fixtures
  Fixtures.path = File.expand_path('fixtures_for_testing_fixtures', File.dirname(__FILE__))
end

describe Fixtures do

  describe '#fixture' do
    it 'loads a fixture' do
      expect(fixture('foo.txt')).to eq 'bar'
    end

    it 'raises an error if the fixture does not exist' do
      expect { fixture('bogux') }.to raise_error Fixtures::NotFound
    end
  end

end