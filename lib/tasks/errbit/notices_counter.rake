namespace :errbit do

  namespace :db do
    desc "Updates Err#notices_count"
    task :update_notices_count => :environment do
      puts "Updating err.notices_count"
      Err.all.each do |e|
        e.update_attributes(:notices_count => e.notices.count)
      end
    end
  end
end
