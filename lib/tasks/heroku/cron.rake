desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
  Rake::Task["errbit:db:clear_resolved"].invoke
end

