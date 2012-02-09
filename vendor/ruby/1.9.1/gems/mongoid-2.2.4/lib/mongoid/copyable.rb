# encoding: utf-8
module Mongoid #:nodoc:

  # This module contains the behaviour of Mongoid's clone/dup of documents.
  module Copyable
    extend ActiveSupport::Concern

    COPYABLES = [
      :@accessed,
      :@attributes,
      :@metadata,
      :@modifications,
      :@previous_modifications
    ]

    protected

    # Clone or dup the current +Document+. This will return all attributes with
    # the exception of the document's id and versions, and will reset all the
    # instance variables.
    #
    # This clone also includes embedded documents.
    #
    # @example Clone the document.
    #   document.clone
    #
    # @example Dup the document.
    #   document.dup
    #
    # @param [ Document ] other The document getting cloned.
    #
    # @return [ Document ] The new document.
    def initialize_copy(other)
      @attributes = other.as_document
      instance_variables.each { |name| remove_instance_variable(name) }
      COPYABLES.each do |name|
        value = other.instance_variable_get(name)
        instance_variable_set(name, value ? value.dup : nil)
      end
      attributes.delete("_id")
      attributes.delete("versions")
      @new_record = true
      identify
    end
  end
end
