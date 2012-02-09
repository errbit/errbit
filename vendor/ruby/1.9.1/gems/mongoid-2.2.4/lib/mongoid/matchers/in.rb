# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:

    # Performs matching for any value in an array.
    class In < Default

      # Return true if the attribute is in the values.
      #
      # @example Do the values match?
      #   matcher.matches?({ :key => 10 })
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If a value exists.
      def matches?(value)
        value.values.first.include?(@attribute)
      end
    end
  end
end
