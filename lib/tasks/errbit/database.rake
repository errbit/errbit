require 'digest/sha1'

namespace :errbit do
  namespace :db do

    desc "Updates cached attributes on Problem"
    task :update_problem_attrs => :environment do
      puts "Updating problems"
      Problem.all.each(&:cache_notice_attributes)
    end

    desc "Updates Problem#notices_count"
    task :update_notices_count => :environment do
      puts "Updating problem.notices_count"
      Problem.all.each do |p|
        p.update_attributes(:notices_count => p.notices.count)
      end
    end

    desc "Delete resolved errors from the database. (Useful for limited heroku databases)"
    task :clear_resolved => :environment do
      count = Problem.resolved.count
      Problem.resolved.each {|problem| problem.destroy }
      puts "=== Cleared #{count} resolved errors from the database." if count > 0
    end

    desc "Scrub backtrace and other data from resolved notices."
    task :scrub_resolved_notices => :environment do
      count = Problem.resolved.count
      Problem.resolved.each {|problem| problem.notices.scrub! }
      puts "=== Scrubbed notices for #{count} resolved errors from the database." if count > 0
    end

    desc "Scrub backtrace and other data from all but most recent 100 notices for problems with more than 100 notices."
    task :scrub_extraneous_notices => :environment do
      count = Problem.unresolved.where(:notices_count.gt => 100).count
      Problem.unresolved.where(:notices_count.gt => 100).each {|problem|
        notice_count = problem.notices.count
        # HACK: Can't just call with #limit scope, because
        # mongoid doesn't play nicely with #limit, unless
        # using #to_a at end.
        # See https://github.com/mongoid/mongoid/issues/1100
        if notice_count > 100 # sometimes cached :notices_count isn't accurate
          hundredth = problem.notices.limit(1).skip(notice_count - 100).first
          problem.notices.where(:created_at.lt => hundredth.created_at).scrub!
        else
          count -= 1
        end
      }
      puts "=== Scrubbed all but most recent 100 notices for #{count} errors from the database." if count > 0
    end
  end
end
