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
require "xmpp4r"
require "xmpp4r/muc"
require "fabrication"
require "sucker_punch/testing/inline"
require "errbit_plugin/mock_issue_tracker"

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
Mongoid::Config.truncate!
Mongoid::Tasks::Database.create_indexes
ActionMailer::Base.delivery_method = :test

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.alias_example_to :fit, focused: true

  config.before(:each) do
    Mongoid::Config.truncate!
  end

  config.include Haml, type: :helper
  config.include Haml::Helpers, type: :helper

  config.before(:each, type: :decorator) do |_|
    Draper::ViewContext.current.class_eval { include Haml::Helpers }
  end
end
