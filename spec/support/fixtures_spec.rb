require_relative 'fixtures'

RSpec.configure do |config|
  config.include Fixtures
end

describe Fixtures do

  before(:all) do
    @tmp_dir = File.join(File.dirname(__FILE__), 'fixtures_tmp')
    FileUtils.mkdir_p(@tmp_dir)
    # Write a sample fixture
    File.open(File.join(@tmp_dir, 'foo.txt'), 'w') { |f| f.write("bar") }
    Fixtures.path = @tmp_dir
  end

  after(:all) do
    FileUtils.remove_entry_secure(@tmp_dir)
    Fixures.path = nil
  end

  describe '#fixture' do
    it 'loads a fixture' do
      expect(fixture('foo.txt')).to eq 'bar'
    end

    it 'raises an error if the fixture does not exist' do
      expect { fixture('bogux') }.to raise_error Fixtures::NotFound
    end
  end

end