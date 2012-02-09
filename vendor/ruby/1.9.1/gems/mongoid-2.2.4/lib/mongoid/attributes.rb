# encoding: utf-8
require "mongoid/attributes/processing"

module Mongoid #:nodoc:

  # This module contains the logic for handling the internal attributes hash,
  # and how to get and set values.
  module Attributes
    include Processing

    attr_reader :attributes
    alias :raw_attributes :attributes

    # Determine if an attribute is present.
    #
    # @example Is the attribute present?
    #   person.attribute_present?("title")
    #
    # @param [ String, Symbol ] name The name of the attribute.
    #
    # @return [ true, false ] True if present, false if not.
    #
    # @since 1.0.0
    def attribute_present?(name)
      attribute = read_attribute(name)
      ! attribute.blank? || attribute == false
    end
    alias :has_attribute? :attribute_present?

    # Read a value from the document attributes. If the value does not exist
    # it will return nil.
    #
    # @example Read an attribute.
    #   person.read_attribute(:title)
    #
    # @example Read an attribute (alternate syntax.)
    #   person[:title]
    #
    # @param [ String, Symbol ] name The name of the attribute to get.
    #
    # @return [ Object ] The value of the attribute.
    #
    # @since 1.0.0
    def read_attribute(name)
      attributes[name.to_s]
    end
    alias :[] :read_attribute

    # Remove a value from the +Document+ attributes. If the value does not exist
    # it will fail gracefully.
    #
    # @example Remove the attribute.
    #   person.remove_attribute(:title)
    #
    # @param [ String, Symbol ] name The name of the attribute to remove.
    #
    # @since 1.0.0
    def remove_attribute(name)
      assigning do
        access = name.to_s
        attribute_will_change!(access)
        attributes.delete(access)
      end
    end

    # Override respond_to? so it responds properly for dynamic attributes.
    #
    # @example Does this object respond to the method?
    #   person.respond_to?(:title)
    #
    # @param [ Array ] *args The name of the method.
    #
    # @return [ true, false ] True if it does, false if not.
    #
    # @since 1.0.0
    def respond_to?(*args)
      (Mongoid.allow_dynamic_fields &&
        attributes &&
        attributes.has_key?(args.first.to_s)
      ) || super
    end

    # Write a single attribute to the document attribute hash. This will
    # also fire the before and after update callbacks, and perform any
    # necessary typecasting.
    #
    # @example Write the attribute.
    #   person.write_attribute(:title, "Mr.")
    #
    # @example Write the attribute (alternate syntax.)
    #   person[:title] = "Mr."
    #
    # @param [ String, Symbol ] name The name of the attribute to update.
    # @param [ Object ] value The value to set for the attribute.
    #
    # @since 1.0.0
    def write_attribute(name, value)
      assigning do
        access = name.to_s
        typed_value_for(access, value).tap do |value|
          unless attributes[access] == value || attribute_changed?(access)
            attribute_will_change!(access)
          end
          attributes[access] = value
        end
      end
    end
    alias :[]= :write_attribute

    # Writes the supplied attributes hash to the document. This will only
    # overwrite existing attributes if they are present in the new +Hash+, all
    # others will be preserved.
    #
    # @example Write the attributes.
    #   person.write_attributes(:title => "Mr.")
    #
    # @example Write the attributes (alternate syntax.)
    #   person.attributes = { :title => "Mr." }
    #
    # @param [ Hash ] attrs The new attributes to set.
    # @param [ Boolean ] guard_protected_attributes False to skip mass assignment protection.
    #
    # @since 1.0.0
    def write_attributes(attrs = nil, guard_protected_attributes = true)
      assigning do
        process(attrs, guard_protected_attributes) do |document|
          document.identify if new? && id.blank?
        end
      end
    end
    alias :attributes= :write_attributes

    protected

    # Set any missing default values in the attributes.
    #
    # @example Get the raw attributes after defaults have been applied.
    #   person.apply_default_attributes
    #
    # @return [ Hash ] The raw attributes.
    #
    # @since 2.0.0.rc.8
    def apply_default_attributes
      (@attributes ||= {}).tap do |attrs|
        defaults.each do |name|
          unless attrs.has_key?(name)
            if field = fields[name]
              attrs[name] = field.eval_default(self)
            end
          end
        end
      end
    end

    # Begin the assignment of attributes. While in this block embedded
    # documents will not autosave themselves in order to allow the document to
    # be in a valid state.
    #
    # @example Execute the assignment.
    #   assigning do
    #     person.attributes = { :addresses => [ address ] }
    #   end
    #
    # @return [ Object ] The yielded value.
    #
    # @since 2.2.0
    def assigning
      begin
        Threaded.begin_assign
        yield
      ensure
        Threaded.exit_assign
      end
    end

    # Used for allowing accessor methods for dynamic attributes.
    #
    # @param [ String, Symbol ] name The name of the method.
    # @param [ Array ] *args The arguments to the method.
    def method_missing(name, *args)
      attr = name.to_s
      return super unless attributes.has_key?(attr.reader)
      if attr.writer?
        write_attribute(attr.reader, (args.size > 1) ? args : args.first)
      else
        read_attribute(attr.reader)
      end
    end

    # Return the typecasted value for a field.
    #
    # @example Get the value typecasted.
    #   person.typed_value_for(:title, :sir)
    #
    # @param [ String, Symbol ] key The field name.
    # @param [ Object ] value The uncast value.
    #
    # @return [ Object ] The cast value.
    #
    # @since 1.0.0
    def typed_value_for(key, value)
      fields.has_key?(key) ? fields[key].serialize(value) : value
    end
  end
end
