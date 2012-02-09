# encoding: utf-8
module Mongoid #:nodoc:

  # Instantiates documents that came from the database.
  module Factory
    extend self

    # Builds a new +Document+ from the supplied attributes.
    #
    # @example Build the document.
    #   Mongoid::Factory.build(Person, { "name" => "Durran" })
    #
    # @param [ Class ] klass The class to instantiate from if _type is not present.
    # @param [ Hash ] attributes The document attributes.
    #
    # @return [ Document ] The instantiated document.
    def build(klass, attributes = {})
      type = (attributes || {})["_type"]
      (type && klass._types.include?(type)) ? type.constantize.new(attributes) : klass.new(attributes)
    end

    # Builds a new +Document+ from the supplied attributes loaded from the
    # database.
    #
    # @example Build the document.
    #   Mongoid::Factory.from_db(Person, { "name" => "Durran" })
    #
    # @param [ Class ] klass The class to instantiate from if _type is not present.
    # @param [ Hash ] attributes The document attributes.
    #
    # @return [ Document ] The instantiated document.
    def from_db(klass, attributes = {})
      type = attributes["_type"]
      type.blank? ? klass.instantiate(attributes) : type.constantize.instantiate(attributes)
    end
  end
end
