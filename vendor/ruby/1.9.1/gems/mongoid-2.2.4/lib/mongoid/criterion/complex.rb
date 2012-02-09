# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:

    # Complex criterion are used when performing operations on symbols to get
    # get a shorthand syntax for where clauses.
    #
    # @example Conversion of a simple to complex criterion.
    #   { :field => { "$lt" => "value" } }
    #   becomes:
    #   { :field.lt => "value }
    class Complex
      attr_accessor :key, :operator

      # Create the new complex criterion.
      #
      # @example Instantiate a new complex criterion.
      #   Complex.new(:key => :field, :operator => "$gt")
      #
      # @param [ Hash ] opts The options to convert.
      def initialize(opts = {})
        @key, @operator = opts[:key], opts[:operator]
      end

      # Get the criterion as a hash.
      #
      # @example Get the criterion as a hash.
      #   criterion.hash
      #
      # @return [ Hash ] The keys and operators.
      def hash
        [@key, @operator].hash
      end

      # Is the criterion equal to the other?
      #
      # @example Check equality.
      #   criterion.eql?(other)
      #
      # @param [ Complex ] other The other complex criterion.
      #
      # @return [ true, false ] If they are equal.
      def eql?(other)
        self == (other)
      end

      # Is the criterion equal to the other?
      #
      # @example Check equality.
      #   criterion == other
      #
      # @param [ Complex ] other The other complex criterion.
      #
      # @return [ true, false ] If they are equal.
      def ==(other)
        return false unless other.is_a?(self.class)
        self.key == other.key && self.operator == other.operator
      end

      # Returns the name of the key as a string.
      #
      # @example Get the name of the key.
      #   criterion.to_s
      #
      # @return [ String ] The field name.
      #
      # @since 2.1.0
      def to_s
        key.to_s
      end
    end
  end
end
