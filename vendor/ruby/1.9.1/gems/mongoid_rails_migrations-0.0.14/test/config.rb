require File.join(File.dirname(__FILE__), '..', 'lib', 'mongoid_rails_migrations')
require File.join(File.dirname(__FILE__), '..', 'lib', 'rails', 'generators', 'mongoid', 'mongoid_generator')

Mongoid.configure do |config|
  name = "mongoid_test"
  host = "localhost"
  config.master = Mongo::Connection.new.db(name)
end

# require all models
Dir[ File.join(File.dirname(__FILE__), 'models', '*.rb') ].each {|file| require file }

MIGRATIONS_ROOT = File.join(File.dirname(__FILE__), 'migrations')