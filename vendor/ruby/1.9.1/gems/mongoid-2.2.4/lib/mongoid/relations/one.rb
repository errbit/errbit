# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This is the superclass for one to one relations and defines the common
    # behaviour or those proxies.
    class One < Proxy

      # Get all the documents in the relation that are loaded into memory.
      #
      # @example Get the in memory documents.
      #   relation.in_memory
      #
      # @return [ Array<Document> ] The documents in memory.
      #
      # @since 2.1.0
      def in_memory
        [ target ]
      end

      # Since method_missing is overridden we should override this as well.
      #
      # @example Does the proxy respond to the method?
      #   relation.respond_to?(:name)
      #
      # @param [ Symbol ] name The method name.
      #
      # @return [ true, false ] If the proxy responds to the method.
      #
      # @since 2.1.8
      def respond_to?(name, include_private = false)
        target.respond_to?(name, include_private) || super
      end
    end
  end
end
