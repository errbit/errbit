# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:

      # Defines the behaviour for nil fields.
      class NilClass
        include Serializable

        # Deserialize this field from the type stored in MongoDB to the type
        # defined on the model
        #
        # @example Deserialize the field.
        #   field.deserialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ nil ] Always nil.
        #
        # @since 2.1.0
        def deserialize(object); nil; end

        # Serialize the object from the type defined in the model to a MongoDB
        # compatible object to store.
        #
        # @example Serialize the field.
        #   field.serialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ nil ] always nil.
        #
        # @since 2.1.0
        def serialize(object); nil; end
      end
    end
  end
end
