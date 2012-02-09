# encoding: utf-8
module Rack #:nodoc:
  module Mongoid #:nodoc:
    module Middleware #:nodoc:

      # This middleware contains the behaviour needed to properly use the
      # identity map in Rack based applications.
      class IdentityMap

        # Initialize the new middleware.
        #
        # @example Init the middleware.
        # IdentityMap.new(app)
        #
        # @param [ Object ] app The application.
        #
        # @since 2.1.0
        def initialize(app)
          @app = app
        end

        # Make the request with the provided environment.
        #
        # @example Make the request.
        # identity_map.call(env)
        #
        # @param [ Object ] env The environment.
        #
        # @return [ Array ] The status, headers, and response.
        #
        # @since 2.1.0
        def call(env)
          ::Mongoid.unit_of_work { @app.call(env) }
        end
      end
    end
  end
end
