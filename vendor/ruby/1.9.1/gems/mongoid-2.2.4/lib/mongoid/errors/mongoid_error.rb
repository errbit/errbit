# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Default parent Mongoid error for all custom errors. This handles the base
    # key for the translations and provides the convenience method for
    # translating the messages.
    class MongoidError < StandardError
      BASE_KEY = "mongoid.errors.messages"

      # Given the key of the specific error and the options hash, translate the
      # message.
      #
      # @example Translate the message.
      #   error.translate("errors", :key => value)
      #
      # @param [ String ] key The key of the error in the locales.
      # @param [ Hash ] options The objects to pass to create the message.
      #
      # @return [ String ] A localized error message string.
      def translate(key, options)
        ::I18n.translate("#{BASE_KEY}.#{key}", options)
      end
    end
  end
end
