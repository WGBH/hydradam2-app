if ENV['TRAVIS'] || ENV['COVERAGE']
  require 'coveralls'
  Coveralls.wear!
end

require 'pry'
require 'webmock/rspec'

# Add spec/support to load path.
$LOAD_PATH.unshift(File.expand_path('../support', __FILE__))

RSpec.configure do |config|

  # Make sure WebMock doesn't prevent other tests from running;
  # must therefore explicitly enable/disable in test desired suite
  WebMock.allow_net_connect!

  # Allow skipping tests with metadata using RSPEC_SKIP env var.
  # E.g. skip any tests tagged with :foo => "bar" OR :baz like this:
  #  RSPEC_SKIP=foo:bar,baz
  if ENV['RSPEC_SKIP']
    exclusion_hash = Hash[
      ENV['RSPEC_SKIP'].split(',').map do |str|
        key, val = str.split(':');
        val ||= true;
        [key.to_sym, val]
      end
    ]
    config.filter_run_excluding(exclusion_hash)
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end