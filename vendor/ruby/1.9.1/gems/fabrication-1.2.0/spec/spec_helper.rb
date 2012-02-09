require 'rspec'
require 'fabrication'
require 'ffaker'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

RSpec.configure do |config|
  config.before(:all) { TestMigration.up }
  config.before(:all) { clear_mongodb }
end
