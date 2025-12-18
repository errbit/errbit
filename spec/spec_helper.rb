# frozen_string_literal: true

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"

require "simplecov"

SimpleCov.start "rails" do
  enable_coverage :branch
  primary_coverage :branch
  # https://github.com/simplecov-ruby/simplecov/issues/1057
  # enable_coverage_for_eval

  add_group "Decorators", "app/decorators"
  add_group "Interactors", "app/interactors"
  add_group "Policies", "app/policies"
end

require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
require "email_spec"
require "errbit_plugin/mock_issue_tracker"

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  # https://rspec.info/features/3-12/rspec-core/configuration/zero-monkey-patching-mode/
  config.disable_monkey_patching!
end
