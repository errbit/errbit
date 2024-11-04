require 'net/http'
require 'net/https'
require 'rubygems'
begin
  require 'active_support'
rescue LoadError
  require 'activesupport'
end
require 'hoptoad_notifier/version'
require 'hoptoad_notifier/configuration'
require 'hoptoad_notifier/notice'
require 'hoptoad_notifier/sender'
require 'hoptoad_notifier/backtrace'
require 'hoptoad_notifier/rack'
require 'hoptoad_notifier/user_informer'

require 'hoptoad_notifier/railtie' if defined?(Rails::Railtie)

# Gem for applications to automatically post errors to the Hoptoad of their choice.
module HoptoadNotifier

  API_VERSION = "2.0"
  LOG_PREFIX = "** [Hoptoad] "

  HEADERS = {
    'Content-type'             => 'text/xml',
    'Accept'                   => 'text/xml, application/xml'
  }

  class << self
    # The sender object is responsible for delivering formatted data to the Hoptoad server.
    # Must respond to #send_to_hoptoad. See HoptoadNotifier::Sender.
    attr_accessor :sender

    # A Hoptoad configuration object. Must act like a hash and return sensible
    # values for all Hoptoad configuration options. See HoptoadNotifier::Configuration.
    attr_accessor :configuration

    # Tell the log that the Notifier is good to go
    def report_ready
      write_verbose_log("Notifier #{VERSION} ready to catch errors")
    end

    # Prints out the environment info to the log for debugging help
    def report_environment_info
      write_verbose_log("Environment Info: #{environment_info}")
    end

    # Prints out the response body from Hoptoad for debugging help
    def report_response_body(response)
      write_verbose_log("Response from Hoptoad: \n#{response}")
    end

    # Returns the Ruby version, Rails version, and current Rails environment
    def environment_info
      info = "[Ruby: #{RUBY_VERSION}]"
      info << " [#{configuration.framework}]"
      info << " [Env: #{configuration.environment_name}]"
    end

    # Writes out the given message to the #logger
    def write_verbose_log(message)
      logger.info LOG_PREFIX + message if logger
    end

    # Look for the Rails logger currently defined
    def logger
      self.configuration.logger
    end

    # Call this method to modify defaults in your initializers.
    #
    # @example
    #   HoptoadNotifier.configure do |config|
    #     config.api_key = '1234567890abcdef'
    #     config.secure  = false
    #   end
    def configure(silent = false)
      self.configuration ||= Configuration.new
      yield(configuration)
      self.sender = Sender.new(configuration)
      report_ready unless silent
    end

    # Sends an exception manually using this method, even when you are not in a controller.
    #
    # @param [Exception] exception The exception you want to notify Hoptoad about.
    # @param [Hash] opts Data that will be sent to Hoptoad.
    #
    # @option opts [String] :api_key The API key for this project. The API key is a unique identifier that Hoptoad uses for identification.
    # @option opts [String] :error_message The error returned by the exception (or the message you want to log).
    # @option opts [String] :backtrace A backtrace, usually obtained with +caller+.
    # @option opts [String] :request The controller's request object.
    # @option opts [String] :session The contents of the user's session.
    # @option opts [String] :environment ENV merged with the contents of the request's environment.
    def notify(exception, opts = {})
      send_notice(build_notice_for(exception, opts))
    end

    # Sends the notice unless it is one of the default ignored exceptions
    # @see HoptoadNotifier.notify
    def notify_or_ignore(exception, opts = {})
      notice = build_notice_for(exception, opts)
      send_notice(notice) unless notice.ignore?
    end

    def build_lookup_hash_for(exception, options = {})
      notice = build_notice_for(exception, options)

      result = {}
      result[:action]           = notice.action      rescue nil
      result[:component]        = notice.component   rescue nil
      result[:error_class]      = notice.error_class if notice.error_class
      result[:environment_name] = 'production'

      unless notice.backtrace.lines.empty?
        result[:file]        = notice.backtrace.lines.first.file
        result[:line_number] = notice.backtrace.lines.first.number
      end

      result
    end

    private

    def send_notice(notice)
      if configuration.public?
        sender.send_to_hoptoad(notice.to_xml)
      end
    end

    def build_notice_for(exception, opts = {})
      exception = unwrap_exception(exception)
      if exception.respond_to?(:to_hash)
        opts = opts.merge(exception.to_hash)
      else
        opts = opts.merge(:exception => exception)
      end
      Notice.new(configuration.merge(opts))
    end

    def unwrap_exception(exception)
      if exception.respond_to?(:original_exception)
        exception.original_exception
      elsif exception.respond_to?(:continued_exception)
        exception.continued_exception
      else
        exception
      end
    end
  end
end

