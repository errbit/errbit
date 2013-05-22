# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'database_cleaner'
require 'webmock/rspec'
require 'xmpp4r'
require 'xmpp4r/muc'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

Fabrication.configure do |config|
  fabricator_dir = "spec/fabricators"
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.include Devise::TestHelpers, :type => :controller
  config.filter_run :focused => true
  config.run_all_when_everything_filtered = true
  config.alias_example_to :fit, :focused => true

  config.before(:each) do
    DatabaseCleaner[:mongoid].strategy = :truncation
    DatabaseCleaner.clean
  end
  config.include WebMock::API

  config.include Haml, :type => :helper
  config.include Haml::Helpers, :type => :helper
  config.before(:each, :type => :helper) do |config|
    init_haml_helpers
  end
end

OmniAuth.config.test_mode = true
