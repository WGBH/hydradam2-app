# FIXME: configure library includes
require './lib/hydradam/preingest/IU/sip'

namespace :hydradam do
  desc "Preingest one or more files of chosen type, in specified folder"
  task :preingest, [:package_type] => :environment do |task, args|
    file = ARGV[1]
    abort "usage: rake hydradam:preingest[package_type] /path/to/preingest/file" unless args.package_type && file
    abort "File not found: #{file}" unless File.exists?(file)
    abort "Directory given instead of file: #{file}" if Dir.exists?(file)
    begin
      class_string = "HydraDAM::Preingest::#{args.package_type.titleize.split.join.gsub('/', '::').gsub('Iu', 'IU')}"
      package_class = class_string.constantize
    rescue
      abort "unknown preingest pipeline: #{args.package_type} => #{class_string}"
    end

    user = User.find_by_user_key( ENV['USER'] ) if ENV['USER']
    user = User.first unless user
    abort "User unspecified or not found" unless user

    logger = Logger.new(STDOUT)
    PreingestJob.logger = logger
    logger.info "preingesting file: #{file}"
    logger.info "preingesting as: #{user.user_key} (override with USER=foo)"
    abort "Missing preingest file: #{file}" unless File.exist?(file)
    begin
      PreingestJob.perform_now(package_class, file, user)
    rescue => e
      puts "Error: #{e.message}"
      puts e.backtrace
    end
  end
end
