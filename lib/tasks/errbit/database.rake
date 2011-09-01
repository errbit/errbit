namespace :errbit do
  namespace :db do
    desc "Updates Err#notices_count"
    task :update_err_message => :environment do
      puts "Updating err.message"
      Err.all.each do |e|
        e.update_attributes(:message => e.notices.first.message) if e.notices.first
      end
    end

    desc "Updates Err#notices_count"
    task :update_notices_count => :environment do
      puts "Updating err.notices_count"
      Err.all.each do |e|
        e.update_attributes(:notices_count => e.notices.count)
      end
    end

    desc "Delete resolved errors from the database. (Useful for limited heroku databases)"
    task :clear_resolved => :environment do
      count = Err.resolved.count
      Err.resolved.each {|err| err.destroy }
      puts "=== Cleared #{count} resolved errors from the database." if count > 0
    end
  end
end

