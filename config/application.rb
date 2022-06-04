require_relative "boot"

require "rails"
# Pick the frameworks you want:
# require "active_model/railtie"
# require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
# require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Errbit
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.eager_load_paths << Rails.root.join('lib')

    config.before_initialize do
      config.secret_key_base = Errbit::Config.secret_key_base
      config.serve_static_files = Errbit::Config.serve_static_assets
    end

    initializer 'errbit.mongoid', before: 'mongoid.load-config' do
      require Rails.root.join('config/mongo')
    end

    # > rails generate - config
    config.generators do |g|
      g.orm :mongoid
      g.template_engine :haml
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :fabrication
    end

    # IssueTracker subclasses use inheritance, so preloading models provides querying consistency in dev mode.
    config.mongoid.preload_models = true

    # Configure Devise mailer to use our mailer layout.
    config.to_prepare { Devise::Mailer.layout 'mailer' }

    config.active_job.queue_adapter = :sucker_punch
  end
end
