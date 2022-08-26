module HoptoadNotifier
  module Rails
    module ErrorLookup

      # Sets up an alias chain to catch exceptions when Rails does
      def self.included(base) #:nodoc:
        base.send(:alias_method, :rescue_action_locally_without_hoptoad, :rescue_action_locally)
        base.send(:alias_method, :rescue_action_locally, :rescue_action_locally_with_hoptoad)
      end

      private

      def rescue_action_locally_with_hoptoad(exception)
        result = rescue_action_locally_without_hoptoad(exception)

        if HoptoadNotifier.configuration.development_lookup
          path   = File.join(File.dirname(__FILE__), '..', '..', 'templates', 'rescue.erb')
          notice = HoptoadNotifier.build_lookup_hash_for(exception, hoptoad_request_data)

          result << @template.render(
            :file          => path,
            :use_full_path => false,
            :locals        => { :host    => HoptoadNotifier.configuration.host,
                                :api_key => HoptoadNotifier.configuration.api_key,
                                :notice  => notice })
        end

        result
      end
    end
  end
end

