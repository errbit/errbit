require 'fileutils'

namespace :errbit do

  desc "Copys of example config files"
  task :copy_configs do
    configs = {
      'config.example.yml'  => 'config.yml',
      'deploy.example.rb'   => 'deploy.rb',
      'database.example.yml'   => 'database.yml',
    }

    puts "Copying example config files..."
    configs.each do |old, new|
      if File.exists?("config/#{new}")
        puts "-- Skipping config/#{new}: already exists"
      else
        puts "-- Copying config/#{old} to config/#{new}"
        FileUtils.cp "config/#{old}", "config/#{new}"
      end
    end
  end

  desc "Copy's over example files and seeds the database"
  task :bootstrap do
    Rake::Task['errbit:copy_configs'].execute
    puts "\n"
    Rake::Task['db:seed'].invoke
  end

end
