# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # Used for converting foreign key values to the correct type based on the
    # types of ids that the document stores.
    #
    # @note Durran: The name of this class is this way to match the metadata
    #   getter, and foreign_key was already taken there.
    class Constraint
      attr_reader :metadata

      # Create the new constraint with the metadata.
      #
      # @example Instantiate the constraint.
      #   Constraint.new(metdata)
      #
      # @param [ Metadata ] metadata The metadata of the relation.
      #
      # @since 2.0.0.rc.7
      def initialize(metadata)
        @metadata = metadata
      end

      # Convert the supplied object to the appropriate type to set as the
      # foreign key for a relation.
      #
      # @example Convert the object.
      #   constraint.convert("12345")
      #
      # @param [ Object ] object The object to convert.
      #
      # @return [ Object ] The object cast to the correct type.
      #
      # @since 2.0.0.rc.7
      def convert(object)
        return object if metadata.polymorphic?
        BSON::ObjectId.convert(metadata.klass, object)
      end
    end
  end
end
