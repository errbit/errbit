require 'digest/sha1'

namespace :errbit do
  namespace :db do

    def cleanup_defunct_errs_and_problems
      puts "Cleaning up defunct Errs"
      Err.create_indexes
      Err.all.no_timeout.each do |err|
        err.delete if err.notices.count <= 0
      end
      puts

      puts "Cleaning up defunct Problems"
      Problem.create_indexes
      Problem.all.no_timeout.each do |prob|
        prob.delete if prob.errs.count <= 0
      end
      puts

      Rake::Task["errbit:db:update_problem_attrs"].execute
      Rake::Task["errbit:db:update_notices_count"].execute
      puts
    end

    desc "Updates cached attributes on Problem"
    task :update_problem_attrs => :environment do
      puts "Updating problems"
      Problem.no_timeout.all.each do |problem|
        ProblemUpdaterCache.new(problem).update
      end
    end

    desc "Updates Problem#notices_count"
    task :update_notices_count => :environment do
      puts "Updating problem.notices_count"
      Problem.no_timeout.all.each do |pr|
        pr.update_attributes(:notices_count => pr.notices.count)
      end
    end

    desc "Delete resolved errors from the database. (Useful for limited heroku databases)"
    task :clear_resolved => :environment do
      require 'resolved_problem_clearer'
      puts "=== Cleared #{ResolvedProblemClearer.new.execute} resolved errors from the database."
    end

    desc "Regenerate fingerprints"
    task :regenerate_fingerprints => :environment do
      total = Notice.count
      done  = 0
      last_report = 0.0

      puts "Regenerating err fingerprints for %d notices..." % [total]
      Err.create_indexes
      Notice.all.no_timeout.each do |notice|
        done += 1
        pct = 100.0 * done / total
        if pct - last_report > 1
          last_report = pct
          puts "%.0f%%" % [pct]
        end

        next unless notice.err.present? && notice.err.problem.present?

        fingerprint = ErrorReport.fingerprint_strategy.generate(notice, notice.app.api_key)
        notice.err = notice.app.find_or_create_err!(error_class: notice.error_class,
                                                    environment: notice.problem.environment,
                                                    fingerprint: fingerprint)
        notice.save
      end
      puts

      cleanup_defunct_errs_and_problems

      puts "All done!"
    end

    desc "Discard duplicate notices, keeping only N examples of each err"
    task :notices_cull, [ :n ] => :environment do |_, args|
      n = args[:n].to_i
      raise ArgumentError, "Please specify how many notices to keep" unless n > 0

      total = Err.count
      done  = 0
      last_report = 0.0

      puts "Culling redundant notices for %d errs..." % [total]
      Err.all.no_timeout.each do |err|
        done += 1
        pct = 100.0 * done / total
        if pct - last_report > 1
          last_report = pct
          puts "%.0f%%" % [pct]
        end

        if err.notices.count > n
          to_delete = err.notices.count - n
          puts "  cleaning up Err/#{err.id} (#{to_delete} notices)" if to_delete > 1000
          (err.notices.to_a[n..-1] || []).each { |notice| notice.destroy }
        end
      end

      cleanup_defunct_errs_and_problems

      puts "All done!"
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
