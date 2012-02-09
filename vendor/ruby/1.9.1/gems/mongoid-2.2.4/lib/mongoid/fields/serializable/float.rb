# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:

      # Defines the behaviour for float fields.
      class Float
        include Serializable

        # Serialize the object from the type defined in the model to a MongoDB
        # compatible object to store.
        #
        # @example Serialize the field.
        #   field.serialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Float ] The converted float.
        #
        # @since 2.1.0
        def serialize(object)
          return nil if object.blank?
          begin
            Float(object)
          rescue ArgumentError => e
            object
          end
        end
      end
    end
  end
end
