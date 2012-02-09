# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:

      # Defines the behaviour for integer fields.
      class Integer
        include Serializable

        # Serialize the object from the type defined in the model to a MongoDB
        # compatible object to store.
        #
        # @example Serialize the field.
        #   field.serialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Integer ] The converted integer.
        #
        # @since 2.1.0
        def serialize(object)
          return nil if object.blank?
          begin
            object.to_s =~ /(^[-+]?[0-9]+$)|(\.0+)$/ ? Integer(object) : Float(object)
          rescue
            object
          end
        end
      end
    end
  end
end
