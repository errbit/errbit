if RUBY_VERSION.to_f >= 1.9
  require 'yaml'
  YAML::ENGINE.yamler = 'syck'
end

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
Errbit::Application.initialize!
