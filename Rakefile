# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => :spec
rescue LoadError
  # no rspec available
end

Rake::Task[:default].clear if Rake::Task.task_defined?(:default)

namespace :spec do
  desc "Preparing test env"
  task :prepare do
    tmp_env = Rails.env
    Rails.env = "test"
    %w( db:drop db:mongoid:create_indexes ).each do |task|
      Rake::Task[task].invoke
    end
    Rails.env = tmp_env
  end
end

Rake::Task["spec"].prerequisites.push("spec:prepare")
task :default => ['spec']
