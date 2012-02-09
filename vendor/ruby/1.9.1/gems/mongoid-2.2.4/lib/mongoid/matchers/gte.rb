# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:

    # Performs Greater than or equal to matching.
    class Gte < Default

      # Return true if the attribute is greater than or equal to the value.
      #
      # @example Do the values match?
      #   matcher.matches?({ :key => 10 })
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If a value exists.
      def matches?(value)
        determine(value, :>=)
      end
    end
  end
end
