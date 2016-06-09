# Do not build this rake task when in production environment.
if Rails && !Rails.env.production?
  namespace :hydradam do

    desc 'HydraDAM rspec task'
    RSpec::Core::RakeTask.new(:rspec) do |task|
      task.rspec_opts      = ENV['RSPEC_OPTS']            if ENV['RSPEC_OPTS'].present?
      task.pattern         = ENV['RSPEC_PATTERN']         if ENV['RSPEC_PATTERN'].present?
      task.exclude_pattern = ENV['RSPEC_EXCLUDE_PATTERN'] if ENV['RSPEC_EXCLUDE_PATTERN'].present?
    end

    desc 'Run tests as if on CI server'
    task :spec do
      ENV['RAILS_ENV'] = 'test'
      ENV['TRAVIS'] = '1'

      # TODO: get values from .fcrepo-wrapper ?
      FcrepoWrapper.wrap(port: 8986, enable_jms: false) do |fc|
        # TODO: get values from .solr-wrapper ?
        SolrWrapper.wrap(port: 8985, verbose: true) do |solr|
          solr.with_collection name: 'hydra-test', dir: File.join(Rails.root, 'solr', 'config') do
            Rake::Task['hydradam:rspec'].invoke
          end
        end
      end
    end
  end
end