# encoding: utf-8
require "mongoid/fields/mappings"
require "mongoid/fields/serializable"
require "mongoid/fields/serializable/timekeeping"
require "mongoid/fields/serializable/array"
require "mongoid/fields/serializable/big_decimal"
require "mongoid/fields/serializable/binary"
require "mongoid/fields/serializable/boolean"
require "mongoid/fields/serializable/date"
require "mongoid/fields/serializable/date_time"
require "mongoid/fields/serializable/float"
require "mongoid/fields/serializable/hash"
require "mongoid/fields/serializable/integer"
require "mongoid/fields/serializable/bignum"
require "mongoid/fields/serializable/fixnum"
require "mongoid/fields/serializable/nil_class"
require "mongoid/fields/serializable/object"
require "mongoid/fields/serializable/object_id"
require "mongoid/fields/serializable/range"
require "mongoid/fields/serializable/set"
require "mongoid/fields/serializable/string"
require "mongoid/fields/serializable/symbol"
require "mongoid/fields/serializable/time"
require "mongoid/fields/serializable/time_with_zone"
require "mongoid/fields/serializable/foreign_keys/array"
require "mongoid/fields/serializable/foreign_keys/object"

module Mongoid #:nodoc

  # This module defines behaviour for fields.
  module Fields
    extend ActiveSupport::Concern

    included do
      field(:_type, :type => String)
      field(:_id, :type => BSON::ObjectId)

      alias :id :_id
      alias :id= :_id=
    end

    # Get the default fields.
    #
    # @note Refactored from using delegate for class load performance.
    #
    # @example Get the defaults.
    #   model.defaults
    #
    # @return [ Array<String> ] The default field names.
    def defaults
      self.class.defaults
    end

    # Get the document's fields.
    #
    # @note Refactored from using delegate for class load performance.
    #
    # @example Get the fields.
    #   model.fields
    #
    # @return [ Hash ] The fields.
    def fields
      self.class.fields
    end

    class << self

      # Stores the provided block to be run when the option name specified is
      # defined on a field.
      #
      # No assumptions are made about what sort of work the handler might
      # perform, so it will always be called if the `option_name` key is
      # provided in the field definition -- even if it is false or nil.
      #
      # @example
      #   Mongoid::Fields.option :required do |model, field, value|
      #     model.validates_presence_of field if value
      #   end
      #
      # @param [ Symbol ] option_name the option name to match against
      # @param [ Proc ] block the handler to execute when the option is
      #   provided.
      #
      # @since 2.1.0
      def option(option_name, &block)
        options[option_name] = block
      end

      # Return a map of custom option names to their handlers.
      #
      # @example
      #   Mongoid::Fields.options
      #   # => { :required => #<Proc:0x00000100976b38> }
      #
      # @return [ Hash ] the option map
      #
      # @since 2.1.0
      def options
        @options ||= {}
      end
    end

    module ClassMethods #:nodoc

      # Returns the default values for the fields on the document.
      #
      # @example Get the defaults.
      #   Person.defaults
      #
      # @return [ Hash ] The field defaults.
      def defaults
        @defaults ||= []
      end

      # Set the defaults for the class.
      #
      # @example Set the defaults.
      #   Person.defaults = defaults
      #
      # @param [ Array ] defaults The array of defaults to set.
      #
      # @since 2.0.0.rc.6
      def defaults=(defaults)
        @defaults = defaults
      end

      # Defines all the fields that are accessible on the Document
      # For each field that is defined, a getter and setter will be
      # added as an instance method to the Document.
      #
      # @example Define a field.
      #   field :score, :type => Integer, :default => 0
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Hash ] options The options to pass to the field.
      #
      # @option options [ Class ] :type The type of the field.
      # @option options [ String ] :label The label for the field.
      # @option options [ Object, Proc ] :default The field's default
      #
      # @return [ Field ] The generated field
      def field(name, options = {})
        check_field_name!(name)
        add_field(name.to_s, options)
      end

      # Return the fields for this class.
      #
      # @example Get the fields.
      #   Person.fields
      #
      # @return [ Hash ] The fields for this document.
      #
      # @since 2.0.0.rc.6
      def fields
        @fields ||= {}
      end

      # Set the fields for the class.
      #
      # @example Set the fields.
      #   Person.fields = fields
      #
      # @param [ Hash ] fields The hash of fields to set.
      #
      # @since 2.0.0.rc.6
      def fields=(fields)
        @fields = fields
      end

      # When inheriting, we want to copy the fields from the parent class and
      # set the on the child to start, mimicking the behaviour of the old
      # class_inheritable_accessor that was deprecated in Rails edge.
      #
      # @example Inherit from this class.
      #   Person.inherited(Doctor)
      #
      # @param [ Class ] subclass The inheriting class.
      #
      # @since 2.0.0.rc.6
      def inherited(subclass)
        super
        subclass.defaults, subclass.fields = defaults.dup, fields.dup
      end

      # Is the field with the provided name a BSON::ObjectId?
      #
      # @example Is the field a BSON::ObjectId?
      #   Person.object_id_field?(:name)
      #
      # @param [ String, Symbol ] name The name of the field.
      #
      # @return [ true, false ] If the field is a BSON::ObjectId.
      #
      # @since 2.2.0
      def object_id_field?(name)
        field_name = name.to_s
        field_name = "_id" if field_name == "id"
        field = fields[field_name]
        field ? field.object_id_field? : false
      end

      # Replace a field with a new type.
      #
      # @example Replace the field.
      #   Model.replace_field("_id", String)
      #
      # @param [ String ] name The name of the field.
      # @param [ Class ] type The new type of field.
      #
      # @return [ Serializable ] The new field.
      #
      # @since 2.1.0
      def replace_field(name, type)
        defaults.delete_one(name)
        add_field(name, fields[name].options.merge(:type => type))
      end

      protected

      # Define a field attribute for the +Document+.
      #
      # @example Set the field.
      #   Person.add_field(:name, :default => "Test")
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Hash ] options The hash of options.
      def add_field(name, options = {})
        meth = options.delete(:as) || name
        Mappings.for(
          options[:type], options[:identity]
        ).instantiate(name, options).tap do |field|
          fields[name] = field
          defaults << name unless field.default.nil?
          create_accessors(name, meth, options)
          process_options(field)

          # @todo Durran: Refactor this once we can depend on at least
          #   ActiveModel greater than 3.0.9. They finally have the ability then
          #   to add attribute methods one at a time. This code will make class
          #   load times extremely slow.
          undefine_attribute_methods
          define_attribute_methods(fields.keys)
        end
      end

      # Run through all custom options stored in Mongoid::Fields.options and
      # execute the handler if the option is provided.
      #
      # @example
      #   Mongoid::Fields.option :custom do
      #     puts "called"
      #   end
      #
      #   field = Mongoid::Fields.new(:test, :custom => true)
      #   Person.process_options(field)
      #   # => "called"
      #
      # @param [ Field ] field the field to process
      def process_options(field)
        field_options = field.options

        Fields.options.each_pair do |option_name, handler|
          if field_options.has_key?(option_name)
            handler.call(self, field, field_options[option_name])
          end
        end
      end

      # Determine if the field name is allowed, if not raise an error.
      #
      # @example Check the field name.
      #   Model.check_field_name!(:collection)
      #
      # @param [ Symbol ] name The field name.
      #
      # @raise [ Errors::InvalidField ] If the name is not allowed.
      #
      # @since 2.1.8
      def check_field_name!(name)
        if Mongoid.destructive_fields.include?(name)
          raise Errors::InvalidField.new(name)
        end
      end

      # Create the field accessors.
      #
      # @example Generate the accessors.
      #   Person.create_accessors(:name, "name")
      #   person.name #=> returns the field
      #   person.name = "" #=> sets the field
      #   person.name? #=> Is the field present?
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Symbol ] meth The name of the accessor.
      # @param [ Hash ] options The options.
      def create_accessors(name, meth, options = {})
        field = fields[name]
        generated_field_methods.module_eval do
          if field.cast_on_read?
            define_method(meth) do
              field.deserialize(read_attribute(name))
            end
          else
            define_method(meth) do
              read_attribute(name).tap do |value|
                if value.is_a?(Array) || value.is_a?(Hash)
                  unless changed_attributes.include?(name)
                    changed_attributes[name] = value.clone
                  end
                end
              end
            end
          end
          define_method("#{meth}=") do |value|
            write_attribute(name, value)
          end
          define_method("#{meth}?") do
            attr = read_attribute(name)
            (options[:type] == Boolean) ? attr == true : attr.present?
          end
        end
      end

      # Include the field methods as a module, so they can be overridden.
      #
      # @example Include the fields.
      #   Person.generated_field_methods
      def generated_field_methods
        @generated_field_methods ||= begin
          Module.new.tap do |mod|
            include mod
          end
        end
      end
    end
  end
end
