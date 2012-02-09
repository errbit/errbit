# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:

      # Defines the behaviour for range fields.
      class Range
        include Serializable

        # Deserialize this field from the type stored in MongoDB to the type
        # defined on the model.
        #
        # @example Deserialize the field.
        #   field.deserialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Range ] The converted range.
        #
        # @since 2.1.0
        def deserialize(object)
          object.nil? ? nil : ::Range.new(object["min"], object["max"])
        end

        # Serialize the object from the type defined in the model to a MongoDB
        # compatible object to store.
        #
        # @example Serialize the field.
        #   field.serialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Hash ] The converted hash.
        #
        # @since 2.1.0
        def serialize(object)
          object.nil? ? nil : { "min" => object.min, "max" => object.max }
        end
      end
    end
  end
end
