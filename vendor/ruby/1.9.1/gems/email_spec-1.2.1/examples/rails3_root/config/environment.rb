# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Rails3Root::Application.initialize!
ActionMailer::Base.default_url_options = { :host => 'example.com' }