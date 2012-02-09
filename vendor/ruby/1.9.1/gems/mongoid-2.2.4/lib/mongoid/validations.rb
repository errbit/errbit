# encoding: utf-8
require "mongoid/validations/associated"
require "mongoid/validations/uniqueness"

module Mongoid #:nodoc:

  # This module provides additional validations that ActiveModel does not
  # provide: validates_associated and validates_uniqueness_of.
  module Validations
    extend ActiveSupport::Concern
    include ActiveModel::Validations

    # Begin the associated validation.
    #
    # @example Begin validation.
    #   document.begin_validate
    #
    # @since 2.1.9
    def begin_validate
      Threaded.begin_validate(self)
    end

    # Exit the associated validation.
    #
    # @example Exit validation.
    #   document.exit_validate
    #
    # @since 2.1.9
    def exit_validate
      Threaded.exit_validate(self)
    end

    # Overrides the default ActiveModel behaviour since we need to handle
    # validations of relations slightly different than just calling the
    # getter.
    #
    # @example Read the value.
    #   person.read_attribute_for_validation(:addresses)
    #
    # @param [ Symbol ] attr The name of the field or relation.
    #
    # @return [ Object ] The value of the field or the relation.
    #
    # @since 2.0.0.rc.1
    def read_attribute_for_validation(attr)
      if relations[attr.to_s]
        begin_validate
        relation = send(attr)
        exit_validate
        relation.do_or_do_not(:in_memory) || relation
      else
        send(attr)
      end
    end

    # Determine if the document is valid.
    #
    # @example Is the document valid?
    #   person.valid?
    #
    # @example Is the document valid in a context?
    #   person.valid?(:create)
    #
    # @param [ Symbol ] context The optional validation context.
    #
    # @return [ true, false ] True if valid, false if not.
    #
    # @since 2.0.0.rc.6
    def valid?(context = nil)
      super context ? context : (new? ? :create : :update)
    end

    # Used to prevent infinite loops in associated validations.
    #
    # @example Is the document validated?
    #   document.validated?
    #
    # @return [ true, false ] Has the document already been validated?
    #
    # @since 2.0.0.rc.2
    def validated?
      Threaded.validated?(self)
    end

    module ClassMethods #:nodoc:

      # Validates whether or not an association is valid or not. Will correctly
      # handle has one and has many associations.
      #
      # @example
      #
      #   class Person
      #     include Mongoid::Document
      #     embeds_one :name
      #     embeds_many :addresses
      #
      #     validates_associated :name, :addresses
      #   end
      #
      # @param [ Array ] *args The arguments to pass to the validator.
      def validates_associated(*args)
        validates_with(AssociatedValidator, _merge_attributes(args))
      end

      # Validates whether or not a field is unique against the documents in the
      # database.
      #
      # @example
      #
      #   class Person
      #     include Mongoid::Document
      #     field :title
      #
      #     validates_uniqueness_of :title
      #   end
      #
      # @param [ Array ] *args The arguments to pass to the validator.
      def validates_uniqueness_of(*args)
        validates_with(UniquenessValidator, _merge_attributes(args))
      end

      protected

      # Adds an associated validator for the relation if the validate option
      # was not provided or set to true.
      #
      # @example Set up validation.
      #   Person.validates_relation(metadata)
      #
      # @param [ Metadata ] metadata The relation metadata.
      #
      # @since 2.0.0.rc.1
      def validates_relation(metadata)
        if metadata.validate?
          validates_associated(metadata.name)
        end
      end
    end
  end
end
