# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This module provides convenience macros for using cyclic embedded
    # relations.
    module Cyclic
      extend ActiveSupport::Concern

      included do
        class_attribute :cyclic
      end

      module ClassMethods #:nodoc:

        # Create a cyclic embedded relation that creates a tree hierarchy for
        # the document and many embedded child documents.
        #
        # @example Set up a recursive embeds many.
        #
        #   class Role
        #     include Mongoid::Document
        #     recursively_embeds_many
        #   end
        #
        # @example The previous example is a shorcut for this.
        #
        #   class Role
        #     include Mongoid::Document
        #     embeds_many :child_roles, :class_name => "Role", :cyclic => true
        #     embedded_in :parent_role, :class_name => "Role", :cyclic => true
        #   end
        #
        # This provides the default nomenclature for accessing a parent document
        # or its children.
        #
        # @since 2.0.0.rc.1
        def recursively_embeds_many
          self.cyclic = true
          embeds_many cyclic_child_name, :class_name => self.name, :cyclic => true
          embedded_in cyclic_parent_name, :class_name => self.name, :cyclic => true
        end

        # Create a cyclic embedded relation that creates a single self
        # referencing relationship for a parent and a single child.
        #
        # @example Set up a recursive embeds one.
        #
        #   class Role
        #     include Mongoid::Document
        #     recursively_embeds_one
        #   end
        #
        # @example The previous example is a shorcut for this.
        #
        #   class Role
        #     include Mongoid::Document
        #     embeds_one :child_role, :class_name => "Role", :cyclic => true
        #     embedded_in :parent_role, :class_name => "Role", :cyclic => true
        #   end
        #
        # This provides the default nomenclature for accessing a parent document
        # or its children.
        #
        # @since 2.0.0.rc.1
        def recursively_embeds_one
          self.cyclic = true
          embeds_one cyclic_child_name(false), :class_name => self.name, :cyclic => true
          embedded_in cyclic_parent_name, :class_name => self.name, :cyclic => true
        end

        private

        # Determines the parent name given the class.
        #
        # @example Determine the parent name.
        #   Role.cyclic_parent_name
        #
        # @return [ String ] "parent_" plus the class name underscored.
        #
        # @since 2.0.0.rc.1
        def cyclic_parent_name
          ("parent_" << self.name.demodulize.underscore.singularize).to_sym
        end

        # Determines the child name given the class.
        #
        # @example Determine the child name.
        #   Role.cyclic_child_name
        #
        # @param [ true, false ] many Is the a many relation?
        #
        # @return [ String ] "child_" plus the class name underscored in
        #   singular or plural form.
        #
        # @since 2.0.0.rc.1
        def cyclic_child_name(many = true)
          ("child_" << self.name.demodulize.underscore.send(many ? :pluralize : :singularize)).to_sym
        end
      end
    end
  end
end
