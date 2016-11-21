namespace :hydradam do
  desc "Preingest one or more files of chosen type, in specified folder"
  task :preingest => :environment do |task, args|
    abort "usage: rake /path/to/preingest_file" unless ARGV[1].present?
    file = ARGV[1]

    user = User.find_by_user_key( ENV['USER'] ) if ENV['USER']
    user = User.all.first unless user
    abort "User unspecified or not found" unless user

    logger = Logger.new(STDOUT)
    PreingestJob.logger = logger
    logger.info "preingesting file: #{file}"
    logger.info "preingesting as: #{user.user_key} (override with USER=foo)"
    abort "Missing preingest file: #{file}" unless File.exist?(file)
    begin
      PreingestJob.perform_now(file, user)
    rescue => e
      puts "Error: #{e.message}"
      puts e.backtrace
    end
  end
end
