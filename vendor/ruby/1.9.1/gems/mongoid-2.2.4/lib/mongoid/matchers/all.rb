# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:

    # Checks that all values match.
    class All < Default

      # Return true if the attribute and first value in the hash are equal.
      #
      # @example Do the values match?
      #   matcher.matches?({ :key => 10 })
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If the values match.
      def matches?(value)
        @attribute == value.values.first
      end
    end
  end
end
