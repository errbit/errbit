# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:

    # Performs less than matching.
    class Lt < Default

      # Return true if the attribute is less than the value.
      #
      # @example Do the values match?
      #   matcher.matches?({ :key => 10 })
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If a value exists.
      def matches?(value)
        determine(value, :<)
      end
    end
  end
end
