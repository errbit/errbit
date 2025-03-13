namespace :errbit do
  desc "Updates cached attributes on Problem"
  task problem_recache: :environment do
    ProblemRecacher.run
  end

  desc "Delete resolved errors from the database. (Useful for limited heroku databases)"
  task clear_resolved: :environment do
    require "resolved_problem_clearer"
    puts "=== Cleared #{ResolvedProblemClearer.new.execute} resolved errors from the database."
  end

  desc "Delete old errors from the database. (Useful for limited heroku databases)"
  task clear_outdated: :environment do
    require "outdated_problem_clearer"
    if Errbit::Config.notice_deprecation_days.present?
      puts "=== Cleared #{OutdatedProblemClearer.new.execute} outdated errors from the database."
    else
      puts "=== ERRBIT_PROBLEM_DESTROY_AFTER_DAYS not set. Old problems will not be destroyed."
    end
  end

  desc "Regenerate fingerprints"
  task notice_refingerprint: :environment do
    NoticeRefingerprinter.run
    ProblemRecacher.run
  end

  desc "Remove notices in batch"
  task :notices_delete, [:problem_id] => [:environment] do
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
