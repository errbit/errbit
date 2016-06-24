# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

# These rake tasks should always be run in the 'test' environment and the
# environment name must be set before loading the Rails application
test_env_tasks = %w(default spec)
if Rake.application.top_level_tasks.any? { |t| test_env_tasks.include?(t) }
  ENV['RAILS_ENV'] = 'test'
end

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
  warn "Notice: no rspec tasks available in this environment"
end
