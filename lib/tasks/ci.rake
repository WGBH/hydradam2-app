# Do not build this rake task when in production environment.
if Rails && !Rails.env.production?
  desc 'Run tests as if on CI server'
  task :ci do
    ENV['RAILS_ENV'] = 'test'
    ENV['TRAVIS'] = '1'

    # TODO: get values from .fcrepo-wrapper ?
    FcrepoWrapper.wrap(port: 8986, enable_jms: false) do |fc|
      # TODO: get values from .solr-wrapper ?
      SolrWrapper.wrap(port: 8985, verbose: true) do |solr|
        solr.with_collection name: 'hydra-test', dir: File.join(Rails.root, 'solr', 'config') do
          Rake::Task['spec'].invoke
        end
      end
    end
  end
end