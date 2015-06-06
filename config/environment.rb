# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Load up Errbit::Config with values from the environment
require Rails.root.join('config/load')

if Errbit::Config.log_location == 'STDOUT'
  Rails.logger = ActiveSupport::Logger.new STDOUT
else
  Rails.logger = ActiveSupport::Logger.new Errbit::Config.log_location
end

Rails.logger.level = Errbit::Config.log_level.to_sym

# Initialize the Rails application.
Rails.application.initialize!
