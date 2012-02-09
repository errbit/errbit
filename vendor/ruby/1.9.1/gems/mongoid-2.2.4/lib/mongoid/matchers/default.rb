# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:

    # Contains all the default behavior for checking for matching documents
    # given MongoDB expressions.
    class Default

      attr_accessor :attribute, :document

      # Creating a new matcher only requires the value.
      #
      # @example Create a new matcher.
      #   Default.new("attribute")
      #
      # @param [ Object ] attribute The current attribute to check against.
      #
      # @since 1.0.0
      def initialize(attribute, document = nil)
        @attribute, @document = attribute, document
      end

      # Return true if the attribute and value are equal, or if it is an array
      # if the value is included.
      #
      # @example Does this value match?
      #   default.matches?("value")
      #
      # @param [ Object ] value The value to check if it matches.
      #
      # @return [ true, false ] True if matches, false if not.
      #
      # @since 1.0.0
      def matches?(value)
        attribute.is_a?(Array) && !value.is_a?(Array) ? attribute.include?(value) : value === attribute
      end

      protected

      # Convenience method for getting the first value in a hash.
      #
      # @example Get the first value.
      #   matcher.first(:test => "value")
      #
      # @param [ Hash ] hash The has to pull from.
      #
      # @return [ Object ] The first value.
      #
      # @since 1.0.0
      def first(hash)
        hash.values.first
      end

      # If object exists then compare the two, otherwise return false
      #
      # @example Determine if we can compare.
      #   matcher.determine("test", "$in")
      #
      # @param [ Object ] value The value to compare with.
      # @param [ Symbol, String ] operator The comparison operation.
      #
      # @return [ true, false ] The comparison or false.
      #
      # @since 1.0.0
      def determine(value, operator)
        attribute ? attribute.send(operator, first(value)) : false
      end
    end
  end
end
