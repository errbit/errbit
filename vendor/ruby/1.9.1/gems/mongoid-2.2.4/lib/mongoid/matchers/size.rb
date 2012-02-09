# encoding: utf-8
module Mongoid #:nodoc:
  module Matchers #:nodoc:

    # Performs size checking.
    class Size < Default

      # Return true if the attribute size is equal to the first value.
      #
      # @example Do the values match?
      #   matcher.matches?({ :key => 10 })
      #
      # @param [ Hash ] value The values to check.
      #
      # @return [ true, false ] If a value exists.
      def matches?(value)
        @attribute.size == value.values.first
      end
    end
  end
end
