# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:

      # Defines the behaviour for array fields.
      class Array
        include Serializable

        # Serialize the object from the type defined in the model to a MongoDB
        # compatible object to store.
        #
        # @example Serialize the field.
        #   field.serialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Array ] The converted object.
        #
        # @since 2.1.0
        def serialize(object)
          raise_or_return(object)
        end

        protected

        # If the value is not an array or nil we will raise an error,
        # otherwise return the value.
        #
        # @example Raise or return the value.
        #   field.raise_or_return([])
        #
        # @param [ Object ] value The value to check.a
        #
        # @raise [ InvalidType ] If not passed an array.
        #
        # @return [ Array ] The array.
        #
        # @since 2.1.0
        def raise_or_return(value)
          unless value.nil? || value.is_a?(::Array)
            raise Mongoid::Errors::InvalidType.new(::Array, value)
          end
          value
        end
      end
    end
  end
end
