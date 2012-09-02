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
