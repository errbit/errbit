require 'action_controller/base'

module Responders
  autoload :FlashResponder,      'responders/flash_responder'
  autoload :HttpCacheResponder,  'responders/http_cache_responder'
  autoload :CollectionResponder, 'responders/collection_responder'

  require 'responders/controller_method'

  class Railtie < ::Rails::Railtie
    config.responders = ActiveSupport::OrderedOptions.new
    if config.respond_to?(:app_generators)
      config.app_generators.scaffold_controller = :responders_controller
    else
      config.generators.scaffold_controller = :responders_controller
    end

    # Add load paths straight to I18n, so engines and application can overwrite it.
    require 'active_support/i18n'
    I18n.load_path << File.expand_path('../responders/locales/en.yml', __FILE__)

    initializer "responders.flash_responder" do |app|
      if app.config.responders.flash_keys
        Responders::FlashResponder.flash_keys = app.config.responders.flash_keys
      end
    end
  end
end
