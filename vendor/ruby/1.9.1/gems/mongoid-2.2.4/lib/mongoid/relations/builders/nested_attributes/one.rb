# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module NestedAttributes #:nodoc:
        class One < NestedBuilder

          attr_accessor :destroy

          # Builds the relation depending on the attributes and the options
          # passed to the macro.
          #
          # This attempts to perform 3 operations, either one of an update of
          # the existing relation, a replacement of the relation with a new
          # document, or a removal of the relation.
          #
          # Example:
          #
          # <tt>one.build(person)</tt>
          #
          # Options:
          #
          # parent: The parent document of the relation.
          def build(parent)
            return if reject?(parent, attributes)
            @existing = parent.send(metadata.name)
            if update?
              existing.attributes = attributes
            elsif replace?
              parent.send(metadata.setter, Mongoid::Factory.build(metadata.klass, attributes))
            elsif delete?
              parent.send(metadata.setter, nil)
            end
          end

          # Create the new builder for nested attributes on one-to-one
          # relations.
          #
          # Example:
          #
          # <tt>One.new(metadata, attributes, options)</tt>
          #
          # Options:
          #
          # metadata: The relation metadata
          # attributes: The attributes hash to attempt to set.
          # options: The options defined.
          #
          # Returns:
          #
          # A new builder.
          def initialize(metadata, attributes, options)
            @attributes = attributes.with_indifferent_access
            @metadata = metadata
            @options = options
            @destroy = @attributes.delete(:_destroy)
          end

          private

          # Is the id in the attribtues acceptable for allowing an update to
          # the existing relation?
          #
          # Example:
          #
          # <tt>acceptable_id?</tt>
          #
          # Returns:
          #
          # True if the id part of the logic will allow an update.
          def acceptable_id?
            id = convert_id(attributes[:id])
            existing.id == id || id.nil? || (existing.id != id && update_only?)
          end

          # Can the existing relation be deleted?
          #
          # Example:
          #
          # <tt>delete?</tt>
          #
          # Returns:
          #
          # True if the relation should be deleted.
          def delete?
            destroyable? && !attributes[:id].nil?
          end

          # Can the existing relation potentially be deleted?
          #
          # Example:
          #
          # <tt>destroyable?({ :_destroy => "1" })</tt>
          #
          # Options:
          #
          # attributes: The attributes to pull the flag from.
          #
          # Returns:
          #
          # True if the relation can potentially be deleted.
          def destroyable?
            [ 1, "1", true, "true" ].include?(destroy) && allow_destroy?
          end

          # Is the document to be replaced?
          #
          # Example:
          #
          # <tt>replace?</tt>
          #
          # Returns:
          #
          # True if the document should be replaced.
          def replace?
            !existing && !destroyable? && !attributes.blank?
          end

          # Should the document be updated?
          #
          # Example:
          #
          # <tt>update?</tt>
          #
          # Returns:
          #
          # True if the object should have its attributes updated.
          def update?
            existing && !destroyable? && acceptable_id?
          end
        end
      end
    end
  end
end
