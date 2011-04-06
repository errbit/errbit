namespace :errbit do

  namespace :db do
    desc "Updates Err#notices_count"
    task :update_err_message => :environment do
      puts "Updating err.message"
      Err.all.each do |e|
        e.update_attributes(:message => e.notices.first.message) if e.notices.first
      end
    end
  end
end
