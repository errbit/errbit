# Load the rails application
require File.expand_path('../application', __FILE__)
if RUBY_VERSION.to_f >= 1.9
  require 'yaml'
  YAML::ENGINE.yamler = 'syck'
end
# Initialize the rails application
Errbit::Application.initialize!

