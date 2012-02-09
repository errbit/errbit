require "heroku/command/base"

module Heroku::Command

  # manage plugins to the heroku gem
  class Plugins < Base

    # plugins
    #
    # list installed plugins
    #
    def index
      ::Heroku::Plugin.list.each do |plugin|
        display plugin
      end
    end

    # plugins:install URL
    #
    # install a plugin
    #
    def install
      plugin = Heroku::Plugin.new(args.shift)
      if plugin.install
        begin
          Heroku::Plugin.load_plugin(plugin.name)
        rescue Exception => ex
          installation_failed(plugin, ex.message)
        end
        display "#{plugin} installed"
      else
        error "Could not install #{plugin}. Please check the URL and try again"
      end
    end

    # plugins:uninstall PLUGIN
    #
    # uninstall a plugin
    #
    def uninstall
      plugin = Heroku::Plugin.new(args.shift)
      plugin.uninstall
      display "#{plugin} uninstalled"
    end

    protected

      def installation_failed(plugin, message)
        plugin.uninstall
        error <<-ERROR
Could not initialize #{plugin}: #{message}

Are you attempting to install a Rails plugin? If so, use the following:

Rails 2.x:
script/plugin install #{plugin.uri}

Rails 3.x:
rails plugin install #{plugin.uri}
        ERROR
      end
  end
end
