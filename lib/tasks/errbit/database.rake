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
  end
end
