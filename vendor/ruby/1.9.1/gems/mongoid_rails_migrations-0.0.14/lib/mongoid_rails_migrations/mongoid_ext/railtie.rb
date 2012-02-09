# encoding: utf-8

if defined?(Rails::Railtie)
  module Rails #:nodoc:
    module Mongoid #:nodoc:
      class Railtie < Rails::Railtie
        if config.respond_to?(:app_generators)
          config.app_generators.orm :mongoid, :migration => true
        else
          config.generators.orm :mongoid, :migration => true
        end
        rake_tasks do
          load "mongoid_rails_migrations/mongoid_ext/railties/database.rake"
        end
      end
    end
  end
end