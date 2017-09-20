namespace :errbit do
  desc "Updates cached attributes on Problem"
  task problem_recache: :environment do
    ProblemRecacher.run
  end

  desc "Delete resolved errors from the database. (Useful for limited heroku databases)"
  task clear_resolved: :environment do
    require 'resolved_problem_clearer'
    puts "=== Cleared #{ResolvedProblemClearer.new.execute} resolved errors from the database."
  end

  desc "Regenerate fingerprints"
  task notice_refingerprint: :environment do
    NoticeRefingerprinter.run
    ProblemRecacher.run
  end

  desc "Remove notices in batch"
  task :notices_delete, [:problem_id] => [:environment] do |_,args|
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

  desc 'Resolves problems that didnt occur for 1 month'
  task :cleanup_by_app, [:app_name] => :environment do |_,args|
    BATCH_SIZE = 50

    app       = App.find_by(name: args[:app_name])
    offset    = 1.month.ago
    criteria  = Problem.unresolved.where(:updated_at.lt => offset)
    
    puts "Going to resolve #{criteria.count} problems for #{app.name}"
    while criteria.count > 0
      criteria.limit(BATCH_SIZE).map(&:resolve!)
      print "#{criteria.count.to_s.rjust(4)} remains\r"
    end
    puts "Done..." + " " * 20
  end

  desc "Resolve problems in batch"
  task :resolve_by_match, [:app_name, :problem_matcher] => [:environment] do |_,args|
    BATCH_SIZE  = 50
    MATCH       = Regexp.new args[:problem_matcher]
    
    app         = App.find_by(name: args[:app_name])
    criteria    = Problem.where(message: MATCH, app_name: app.name).unresolved
    item_count  = criteria.count

    puts "There is #{item_count} matching problems to resolve:"
    resolved_count = 0
    while item_count > 0
      resolved_count += criteria.limit(BATCH_SIZE).map(&:resolve!).size
      item_count -= BATCH_SIZE
      puts "  resolved #{resolved_count} problems"
    end
    puts "Done"
  end
end
