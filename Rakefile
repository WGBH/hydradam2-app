# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

require 'solr_wrapper/rake_task'

# unless Rake::Task.task_defined? :spec
#   begin
#     require 'rspec/core/rake_task'
#     RSpec::Core::RakeTask.new(:spec)
#   rescue LoadError
#     # no rspec available
#   end
# end

task('spec').clear
desc 'Run HydraDAM specs'
task spec: 'hydradam:spec'

desc 'Run HydraDAM CI tests'
task ci: 'spec'

task default: 'ci'