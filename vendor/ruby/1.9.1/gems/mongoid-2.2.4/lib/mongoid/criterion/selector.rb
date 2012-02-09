# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:

    # The selector is a hash-like object that has special behaviour for merging
    # mongoid criteria selectors.
    class Selector < Hash

      attr_reader :fields, :klass

      # Create the new selector.
      #
      # @example Create the selector.
      #   Selector.new(Person)
      #
      # @param [ Class ] klass The class the selector is for.
      #
      # @since 1.0.0
      def initialize(klass)
        @fields, @klass = klass.fields.except("_id", "_type"), klass
      end

      # Set the value for the supplied key, attempting to typecast the value.
      #
      # @example Set the value for the key.
      #   selector["$ne"] = { :name => "Zorg" }
      #
      # @param [ String, Symbol ] key The hash key.
      # @param [ Object ] value The value to set.
      #
      # @since 2.0.0
      def []=(key, value)
        super(key, try_to_typecast(key, value))
      end

      # Merge the selector with another hash.
      #
      # @example Merge the objects.
      #   selector.merge!({ :key => "value" })
      #
      # @param [ Hash, Selector ] other The object to merge with.
      #
      # @return [ Selector ] The merged selector.
      #
      # @since 1.0.0
      def merge!(other)
        tap do |selector|
          other.each_pair do |key, value|
            selector[key] = value
          end
        end
      end
      alias :update :merge!

      if RUBY_VERSION < '1.9'

        # Generate pretty inspection for old ruby versions.
        #
        # @example Inspect the selector.
        #   selector.inspect
        #
        # @return [ String ] The inspected selector.
        def inspect
          ret = self.keys.inject([]) do |ret, key|
            ret << "#{key.inspect}=>#{self[key].inspect}"
          end
          "{#{ret.sort.join(', ')}}"
        end
      end

      private

      # If the key is defined as a field, then attempt to typecast it.
      #
      # @example Try to cast.
      #   selector.try_to_typecast(:id, 1)
      #
      # @param [ String, Symbol ] key The field name.
      # @param [ Object ] value The value.
      #
      # @return [ Object ] The typecasted value.
      #
      # @since 1.0.0
      def try_to_typecast(key, value)
        access = key.to_s
        return value unless fields.has_key?(access)
        field = fields[access]
        typecast_value_for(field, value)
      end

      # Get the typecast value for the defined field.
      #
      # @example Get the typecast value.
      #   selector.typecast_value_for(:name, "Corbin")
      #
      # @param [ Field ] field The defined field.
      # @param [ Object ] value The value to cast.
      #
      # @return [ Object ] The cast value.
      #
      # @since 1.0.0
      def typecast_value_for(field, value)
        return field.serialize(value) if field.type === value
        case value
        when Hash
          value = value.dup
          value.each_pair do |k, v|
            value[k] = typecast_hash_value(field, k, v)
          end
        when Array
          value.map { |v| typecast_value_for(field, v) }
        when Regexp
          value
        else
          if field.type == Array
            Serialization.mongoize(value, value.class)
          else
            field.serialize(value)
          end
        end
      end

      # Typecast the value for booleans and integers in hashes.
      #
      # @example Typecast the hash values.
      #   selector.typecast_hash_value(field, "$exists", "true")
      #
      # @param [ Field ] field The defined field.
      # @param [ String ] key The modifier key.
      # @param [ Object ] value The value to cast.
      #
      # @return [ Object ] The cast value.
      #
      # @since 1.0.0
      def typecast_hash_value(field, key, value)
        case key
        when "$exists"
          Serialization.mongoize(value, Boolean)
        when "$size"
          Serialization.mongoize(value, Integer)
        else
          typecast_value_for(field, value)
        end
      end
    end
  end
end
