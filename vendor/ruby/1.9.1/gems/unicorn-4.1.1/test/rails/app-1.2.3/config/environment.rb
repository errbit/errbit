# -*- encoding: binary -*-

unless defined? RAILS_GEM_VERSION
  RAILS_GEM_VERSION = ENV['UNICORN_RAILS_VERSION'] # || '1.2.3'
end

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.frameworks -= [ :action_web_service, :action_mailer ]
  config.action_controller.session_store = :active_record_store
end
