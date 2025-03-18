# frozen_string_literal: true

desc "This task is called by the Heroku cron add-on"
task cron: :environment do
  Rake::Task["errbit:clear_resolved"].invoke
end
