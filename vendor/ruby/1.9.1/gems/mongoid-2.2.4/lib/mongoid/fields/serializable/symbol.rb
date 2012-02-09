# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:

      # Defines the behaviour for symbol fields.
      class Symbol
        include Serializable

        # Serialize the object from the type defined in the model to a MongoDB
        # compatible object to store.
        #
        # @example Serialize the field.
        #   field.serialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Symbol ] The converted symbol.
        #
        # @since 2.1.0
        def serialize(object)
          object.blank? ? nil : object.to_sym
        end
      end
    end
  end
end
