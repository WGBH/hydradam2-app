require 'IU/ingest/sip'

namespace :hydradam do
  namespace :iu do
    desc 'Ingest a SIP tarball'
    task :ingest, [:username, :file] => :environment do |task, args|
      user = User.find_by_email args.username
      sip = IU::Ingest::SIP.new(depositor: user, tarball: args.file)
      sip.ingest!
      print "Ingest complete. Object id: #{sip.work.id}\n"
    end
  end
end