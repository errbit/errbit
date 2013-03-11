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

    desc "Delete resolved errors from the database, optionally only older than 'minage' days."
    task :clear_resolved, [:minage] => :environment do |t, args|
      cutoff = args[:minage] ? DateTime.now - args[:minage].to_i : nil
      count = 0
      Problem.resolved.each do |problem|
        if not cutoff or problem.last_notice_at <= cutoff
          problem.destroy
          count += 1
        end
      end
      puts "=== Cleared #{count} resolved errors from the database." if count > 0
    end

    desc "Regenerate fingerprints"
    task :regenerate_fingerprints => :environment do

      def normalize_backtrace(backtrace)
        backtrace[0...3].map do |trace|
          trace.merge 'method' => trace['method'].to_s.gsub(/[0-9_]{10,}+/, "__FRAGMENT__")
        end
      end

      def fingerprint(source)
        Digest::SHA1.hexdigest(source.to_s)
      end

      puts "Regenerating Err fingerprints"
      Err.create_indexes
      Err.all.each do |err|
        next if err.notices.count == 0
        source = {
          :backtrace => normalize_backtrace(err.notices.first.backtrace).to_s,
          :error_class => err.error_class,
          :component => err.component,
          :action => err.action,
          :environment => err.environment,
          :api_key => err.app.api_key
        }
        err.update_attributes(:fingerprint => fingerprint(source))
      end
    end

    desc "Remove notices in batch"
    task :notices_delete, [ :problem_id ] => [ :environment ] do
      BATCH_SIZE = 1000
      if args[:problem_id]
        item_count = Problem.find(args[:problem_id]).notices.count
        removed_count = 0
        puts "Notices to remove: #{item_count}"
        while item_count > 0
          Problem.find(args[:problem_id]).notices.limit(BATCH_SIZE).each do |notice|
            notice.remove
            removed_count += 1
          end
          item_count -= BATCH_SIZE
          puts "Removed #{removed_count} notices"
        end
      end
    end
  end
end
