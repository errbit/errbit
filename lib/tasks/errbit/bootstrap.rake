require 'fileutils'

namespace :errbit do
  desc "Seed and index the DB"
  task :bootstrap do
    Rake::Task['db:seed'].invoke
    puts "\n"
    Rake::Task['db:mongoid:create_indexes'].invoke
  end
end
