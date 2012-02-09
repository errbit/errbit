# encoding: utf-8
module Mongoid #:nodoc:

  # This module defines the behaviour for overriding the default ids on
  # documents.
  module Keys
    extend ActiveSupport::Concern

    attr_reader :identifier

    included do
      cattr_accessor :primary_key, :using_object_ids
      self.using_object_ids = true
    end

    # Get the document's primary key.
    #
    # @note Refactored from using delegate for class load performance.
    #
    # @example Get the primary key.
    #   model.primary_key
    #
    # @return [ Array ] The primary key
    def primary_key
      self.class.primary_key
    end

    # Is the document using object ids?
    #
    # @note Refactored from using delegate for class load performance.
    #
    # @example Is the document using object ids?
    #   model.using_object_ids?
    #
    # @return [ true, false ] Using object ids.
    def using_object_ids?
      self.class.using_object_ids?
    end

    private

    # Determines if any field that the document id is composed of has changed.
    #
    # @example Has any key field changed?
    #   document.key_field_changed?
    #
    # @return [ true, false ] Has a key field changed?
    #
    # @since 2.0.0
    def key_field_changed?
      primary_key.any? { |field| changed.include?(field.to_s) }
    end

    # Sits around a save when composite keys are in play to handle the id magic
    # if a key field has changed.
    #
    # @example Set the composite key.
    #   document.set_composite_key
    #
    # @param [ Proc ] block The block this surrounds.
    #
    # @since 2.0.0
    def set_composite_key(&block)
      if persisted? && key_field_changed?
        swap_composite_keys(&block)
      else
        identify and block.call
      end
    end

    # Swap out the composite key only after the document has been saved.
    #
    # @example Swap out the keys.
    #   document.swap_composite_keys
    #
    # @param [ Proc ] block The save block getting called.
    #
    # @since 2.0.0
    def swap_composite_keys(&block)
      @identifier, new_id = id.dup, identify
      block.call
      @identifier = nil
    end

    module ClassMethods #:nodoc:

      # Used for telling Mongoid on a per model basis whether to override the
      # default +BSON::ObjectId+ and use a different type. This will be
      # expanded in the future for requiring a PkFactory if the type is not a
      # +BSON::ObjectId+ or +String+.
      #
      # @example Change the documents key type.
      #   class Person
      #     include Mongoid::Document
      #     identity :type => String
      #   end
      #
      # @param [ Hash ] options The options.
      #
      # @option options [ Class ] :type The type of the id.
      #
      # @since 2.0.0.beta.1
      def identity(options = {})
        type = options[:type]
        replace_field("_id", type)
        self.using_object_ids = (type == BSON::ObjectId)
      end

      # Defines the field that will be used for the id of this +Document+. This
      # set the id of this +Document+ before save to a parameterized version of
      # the field that was supplied. This is good for use for readable URLS in
      # web applications.
      #
      # @example Create a composite id.
      #   class Person
      #     include Mongoid::Document
      #     key :first_name, :last_name
      #   end
      #
      # @param [ Array<Symbol> ] The fields the key is composed of.
      #
      # @since 1.0.0
      def key(*fields)
        self.primary_key = fields
        identity(:type => String)
        set_callback(:save, :around, :set_composite_key)
      end

      # Convenience method for determining if we are using +BSON::ObjectIds+ as
      # our id.
      #
      # @example Does this class use object ids?
      #   person.using_object_ids?
      #
      # @return [ true, false ] If the class uses BSON::ObjectIds for the id.
      #
      # @since 1.0.0
      def using_object_ids?
        using_object_ids
      end
    end
  end
end
