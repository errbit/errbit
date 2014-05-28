require 'benchmark'

namespace :errbit do
  namespace :db do

    desc "Runs the defined filters through all notices and if found sets the problem to resolved."
    task :run_filters => :environment do
      notices = Notice.all
      count = notices.count
      found = 0

      puts "Running filters on #{count} notice(s)."
      notices.each do |notice|
        unless notice.app.keep_notice? notice
          notice.problem.update_attribute :resolved, true
          found += 1
        end
      end
      puts "Found a total of #{found} match(es)."
    end
  end
end
