# encoding: utf-8
module Mongoid #:nodoc:
  class Identity #:nodoc:

    attr_reader :document

    # Create the identity for the document. The id will be set in either in
    # the form of a Mongo object id or a composite key set up by defining
    # a key on the document. The _type will be set to the document's class
    # name.
    #
    # @example Create the id and set the type.
    #   identity.create
    def create
      identify.tap { type }
    end

    # Create the new identity generator - this will be expanded in the future
    # to support pk generators.
    #
    # @example
    #   Identity.new(document)
    #
    # @param [ Document ] document The document to generate an id for.
    #
    # @return [ Identity ] The new identity object.
    def initialize(document)
      @document = document
    end

    private

    # Return the proper id for the document. Will be an object id or its string
    # representation depending on the configuration.
    #
    # @example Generate the id.
    #   identity.generate_id
    #
    # @return [ Object ] The bson object id or its string equivalent.
    def generate_id
      id = BSON::ObjectId.new
      document.using_object_ids? ? id : id.to_s
    end

    # Sets the id on the document. Will either set a newly generated id or
    # build the composite key.
    #
    # @example Set the id.
    #   identity.identify
    def identify
      document.id = compose.join(" ").identify if document.primary_key
      document.id = generate_id if document.id.blank?
      document.id
    end

    # Set the _type field on the document if the document is hereditary or in a
    # polymorphic relation.
    #
    # @example Set the type.
    #   identity.type
    def type
      document._type = document.class.name if typed?
    end

    # Generates the array of keys to build the id.
    #
    # @example Build the array for the keys.
    #   identity.compose.
    #
    # @return [ Array<Object> ] The array of keys.
    def compose
      document.primary_key.collect do |key|
        document.attributes[key.to_s]
      end.reject { |val| val.nil? }
    end

    # Determines if the document stores the type information. This is if it is
    # in a hierarchy, has subclasses, or is in a polymorphic relation.
    #
    # @example Check if the document is typed.
    #   identity.typed?
    #
    # @return [ true, false ] True if typed, false if not.
    def typed?
      document.hereditary? ||
        document.class.descendants.any? ||
        document.polymorphic?
    end
  end
end
