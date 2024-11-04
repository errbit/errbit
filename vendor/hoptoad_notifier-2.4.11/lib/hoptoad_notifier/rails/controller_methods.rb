module HoptoadNotifier
  module Rails
    module ControllerMethods
      private

      # This method should be used for sending manual notifications while you are still
      # inside the controller. Otherwise it works like HoptoadNotifier.notify.
      def notify_hoptoad(hash_or_exception)
        unless hoptoad_local_request?
          HoptoadNotifier.notify(hash_or_exception, hoptoad_request_data)
        end
      end
      
      def hoptoad_local_request?
        if defined?(::Rails.application.config)
          ::Rails.application.config.consider_all_requests_local || request.local?
        else
          consider_all_requests_local || local_request?
        end
      end

      def hoptoad_ignore_user_agent? #:nodoc:
        # Rails 1.2.6 doesn't have request.user_agent, so check for it here
        user_agent = request.respond_to?(:user_agent) ? request.user_agent : request.env["HTTP_USER_AGENT"]
        HoptoadNotifier.configuration.ignore_user_agent.flatten.any? { |ua| ua === user_agent }
      end

      def hoptoad_request_data
        { :parameters       => hoptoad_filter_if_filtering(params.to_hash),
          :session_data     => hoptoad_filter_if_filtering(hoptoad_session_data),
          :controller       => params[:controller],
          :action           => params[:action],
          :url              => hoptoad_request_url,
          :cgi_data         => hoptoad_filter_if_filtering(request.env) }
      end

      def hoptoad_filter_if_filtering(hash)
        return hash if ! hash.is_a?(Hash)

        if respond_to?(:filter_parameters)
          filter_parameters(hash) rescue hash
        else
          hash
        end
      end

      def hoptoad_session_data
        if session.respond_to?(:to_hash)
          session.to_hash
        else
          session.data
        end
      end

      def hoptoad_request_url
        url = "#{request.protocol}#{request.host}"

        unless [80, 443].include?(request.port)
          url << ":#{request.port}"
        end

        url << request.fullpath
        url
      end
    end
  end
end

