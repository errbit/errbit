# encoding: utf-8
module Mongoid #:nodoc:

  # The Mongoid logger which wraps some other ruby compliant logger class.
  class Logger

    delegate :info, :debug, :error, :fatal, :unknown, :to => :logger, :allow_nil => true

    # Emit a warning log message.
    #
    # @example Log a warning.
    #   logger.warn("Danger")
    #
    # @param [ String ] message The warning message.
    def warn(message)
      logger.warn(message) if logger && logger.respond_to?(:warn)
    end

    # Get the mongoid logger.
    #
    # @example Get the global logger.
    #   logger.logger
    #
    # @return [ Logger ] The logger.
    def logger
      Mongoid.logger
    end

    # Inspect the logger.
    #
    # @example Inspect the logger.
    #   logger.inspect
    #
    # @return [ String ] The logger, inspected.
    def inspect
      "#<Mongoid::Logger:0x#{object_id.to_s(16)} @logger=#{logger.inspect}>"
    end
  end
end
