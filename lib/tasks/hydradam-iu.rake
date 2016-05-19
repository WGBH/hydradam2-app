require 'IU/ingest/sip'

namespace :hydradam do
  namespace :iu do
    desc 'Ingest a SIP tarball'
    task :ingest, [:username, :file] => :environment do |task, args|
      print "Ingesting #{File.basename(args.file)}...\n"
      user = User.find_by_email args.username
      sip = IU::Ingest::SIP.new(depositor: user, tarball: args.file)
      sip.ingest!
      print "Ingest complete. Object id: #{sip.work.id}\n"
    end

    desc 'Ingest all .tar files in a directory'
    task :ingest_dir, [:username, :dir] => :environment do |task, args|
      files = Dir.glob(File.join(args.dir, '*.tar'))
      files.each do |f|
        Rake::Task['hydradam:iu:ingest'].reenable
        Rake::Task['hydradam:iu:ingest'].invoke(args.username, f)
      end
      print "Ingest of #{args.dir} complete.\n"
    end
  end
end