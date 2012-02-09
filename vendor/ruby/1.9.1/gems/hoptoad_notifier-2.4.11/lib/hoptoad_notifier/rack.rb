module HoptoadNotifier
  # Middleware for Rack applications. Any errors raised by the upstream
  # application will be delivered to Hoptoad and re-raised.
  #
  # Synopsis:
  #
  #   require 'rack'
  #   require 'hoptoad_notifier'
  #
  #   HoptoadNotifier.configure do |config|
  #     config.api_key = 'my_api_key'
  #   end
  #
  #   app = Rack::Builder.app do
  #     use HoptoadNotifier::Rack
  #     run lambda { |env| raise "Rack down" }
  #   end
  #
  # Use a standard HoptoadNotifier.configure call to configure your api key.
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue Exception => raised
        error_id = HoptoadNotifier.notify_or_ignore(raised, :rack_env => env)
        env['hoptoad.error_id'] = error_id
        raise
      end

      if env['rack.exception']
        error_id = HoptoadNotifier.notify_or_ignore(env['rack.exception'], :rack_env => env)
        env['hoptoad.error_id'] = error_id
      end

      response
    end
  end
end
