require 'hoptoad_notifier'
require 'hoptoad_notifier/rails/controller_methods'
require 'hoptoad_notifier/rails/action_controller_catcher'
require 'hoptoad_notifier/rails/error_lookup'
require 'hoptoad_notifier/rails/javascript_notifier'

module HoptoadNotifier
  module Rails
    def self.initialize
      if defined?(ActionController::Base)
        ActionController::Base.send(:include, HoptoadNotifier::Rails::ActionControllerCatcher)
        ActionController::Base.send(:include, HoptoadNotifier::Rails::ErrorLookup)
        ActionController::Base.send(:include, HoptoadNotifier::Rails::ControllerMethods)
        ActionController::Base.send(:include, HoptoadNotifier::Rails::JavascriptNotifier)
      end

      rails_logger = if defined?(::Rails.logger)
                       ::Rails.logger
                     elsif defined?(RAILS_DEFAULT_LOGGER)
                       RAILS_DEFAULT_LOGGER
                     end

      if defined?(::Rails.configuration) && ::Rails.configuration.respond_to?(:middleware)
        ::Rails.configuration.middleware.insert_after 'ActionController::Failsafe',
                                                      HoptoadNotifier::Rack
        ::Rails.configuration.middleware.insert_after 'Rack::Lock',
                                                      HoptoadNotifier::UserInformer
      end

      HoptoadNotifier.configure(true) do |config|
        config.logger = rails_logger
        config.environment_name = RAILS_ENV  if defined?(RAILS_ENV)
        config.project_root     = RAILS_ROOT if defined?(RAILS_ROOT)
        config.framework        = "Rails: #{::Rails::VERSION::STRING}" if defined?(::Rails::VERSION)
      end
    end
  end
end

HoptoadNotifier::Rails.initialize

