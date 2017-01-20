namespace :hydradam do
  desc "Ingest a YAML file"
  task ingest_yaml: :environment do
    file = ARGV[1]
    abort "usage: rake pmp:ingest /path/to/yaml_file" unless file
    abort "File not found: #{file}" unless File.exists?(file)
    abort "Directory given instead of file: #{file}" if Dir.exists?(file)

    user = User.find_by_user_key( ENV['USER'] ) if ENV['USER']
    user = User.first unless user
    abort "User unspecified or not found" unless user
  
    logger = Logger.new(STDOUT)
    IngestYAMLJob.logger = logger
    logger.info "ingesting file: #{file}"
    logger.info "ingesting as: #{user.user_key} (override with USER=foo)"
    begin
      IngestYAMLJob.perform_now(file, user)
    rescue => e
      puts "Error: #{e.message}"
      puts e.backtrace
      abort "Error encountered"
    end
  end
end
