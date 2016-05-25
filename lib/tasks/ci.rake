# Do not build this rake task when in production environment.
if Rails && !Rails.env.production?
  desc 'Run tests as if on CI server'
  task :ci do
    ENV['RAILS_ENV'] = 'test'
    ENV['TRAVIS'] = '1'

    FcrepoWrapper.wrap(port: 8986, enable_jms: false) do |fc|
      SolrWrapper.wrap(port: 8985, verbose: true, instance_dir: "tmp/solr", download_dir: "tmp") do |solr|
        solr.with_collection name: 'hydra-test', dir: File.join(Rails.root, 'solr', 'config') do
          Rake::Task['spec'].invoke
        end
      end
    end
  end
end
