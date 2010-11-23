# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'bundler'

Errbit::Application.load_tasks

Rake::Task[:default].clear

namespace :spec do
  desc "Preparing test env"
  task :prepare do
    tmp_env = Rails.env
    Rails.env = "test"
    %w( errbit:bootstrap ).each do |task|
      Rake::Task[task].invoke
    end
    Rails.env = tmp_env
  end
end

Rake::Task["spec"].prerequisites.push("spec:prepare")
task :default => ['spec']