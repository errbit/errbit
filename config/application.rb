require File.expand_path('../boot', __FILE__)

require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'mongoid/railtie'
require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Errbit
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += [Rails.root.join('lib')]

    config.before_initialize do
      # Load up Errbit::Config with values from the environment
      require Rails.root.join('config/load')

      config.secret_key_base = Errbit::Config.secret_key_base
      config.serve_static_assets = Errbit::Config.serve_static_assets
    end

    initializer 'errbit.mongoid', before: 'mongoid.load-config' do
      require Rails.root.join('config/mongo')
    end

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # > rails generate - config
    config.generators do |g|
      g.orm             :mongoid
      g.template_engine :haml
      g.test_framework  :rspec, :fixture => false
      g.fixture_replacement :fabrication
    end

    # IssueTracker subclasses use inheritance, so preloading models provides querying consistency in dev mode.
    config.mongoid.preload_models = true

    # Configure Devise mailer to use our mailer layout.
    config.to_prepare { Devise::Mailer.layout 'mailer' }
  end
end
