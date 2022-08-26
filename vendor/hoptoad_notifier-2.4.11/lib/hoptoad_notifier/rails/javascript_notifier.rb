module HoptoadNotifier
  module Rails
    module JavascriptNotifier
      def self.included(base) #:nodoc:
        base.send :helper_method, :hoptoad_javascript_notifier
      end

      private

      def hoptoad_javascript_notifier
        return unless HoptoadNotifier.configuration.public?

        path = File.join File.dirname(__FILE__), '..', '..', 'templates', 'javascript_notifier.erb'
        host = HoptoadNotifier.configuration.host.dup
        port = HoptoadNotifier.configuration.port
        host << ":#{port}" unless [80, 443].include?(port)

        options              = {
          :file              => path,
          :layout            => false,
          :use_full_path     => false,
          :locals            => {
            :host            => host,
            :api_key         => HoptoadNotifier.configuration.api_key,
            :environment     => HoptoadNotifier.configuration.environment_name,
            :action_name     => action_name,
            :controller_name => controller_name,
            :url             => request.url
          }
        }

        if @template
          @template.render(options)
        else
          render_to_string(options)
        end

      end

    end
  end
end
