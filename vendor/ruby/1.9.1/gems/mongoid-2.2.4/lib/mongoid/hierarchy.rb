# encoding: utf-8
module Mongoid #:nodoc
  module Hierarchy #:nodoc
    extend ActiveSupport::Concern

    included do
      attr_accessor :_parent
    end

    module ClassMethods #:nodoc:

      # Determines if the document is a subclass of another document.
      #
      # @example Check if the document is a subclass.
      #   Square.hereditary?
      #
      # @return [ true, false ] True if hereditary, false if not.
      def hereditary?
        Mongoid::Document > superclass
      end
    end

    module InstanceMethods #:nodoc:

      # Get all child +Documents+ to this +Document+, going n levels deep if
      # necessary. This is used when calling update persistence operations from
      # the root document, where changes in the entire tree need to be
      # determined. Note that persistence from the embedded documents will
      # always be preferred, since they are optimized calls... This operation
      # can get expensive in domains with large hierarchies.
      #
      # @example Get all the document's children.
      #   person._children
      #
      # @return [ Array<Document> ] All child documents in the hierarchy.
      def _children
        @_children ||=
          [].tap do |children|
            relations.each_pair do |name, metadata|
              if metadata.embedded?
                child = send(name)
                child.to_a.each do |doc|
                  children.push(doc)
                  children.concat(doc._children) unless metadata.versioned?
                end if child
              end
            end
          end
      end

      # Determines if the document is a subclass of another document.
      #
      # @example Check if the document is a subclass
      #   Square.new.hereditary?
      #
      # @return [ true, false ] True if hereditary, false if not.
      def hereditary?
        self.class.hereditary?
      end

      # Sets up a child/parent association. This is used for newly created
      # objects so they can be properly added to the graph.
      #
      # @example Set the parent document.
      #   document.parentize(parent)
      #
      # @param [ Document ] document The parent document.
      #
      # @return [ Document ] The parent document.
      def parentize(document)
        self._parent = document
      end

      # Remove a child document from this parent. If an embeds one then set to
      # nil, otherwise remove from the embeds many.
      #
      # This is called from the +RemoveEmbedded+ persistence command.
      #
      # @example Remove the child.
      #   document.remove_child(child)
      #
      # @param [ Document ] child The child (embedded) document to remove.
      #
      # @since 2.0.0.beta.1
      def remove_child(child)
        name = child.metadata.name
        child.embedded_one? ? remove_ivar(name) : send(name).delete_one(child)
      end

      # After children are persisted we can call this to move all their changes
      # and flag them as persisted in one call.
      #
      # @example Reset the children.
      #   document.reset_persisted_children
      #
      # @return [ Array<Document> ] The children.
      #
      # @since 2.1.0
      def reset_persisted_children
        _children.each do |child|
          child.move_changes
          child.new_record = false
        end
      end

      # Return the root document in the object graph. If the current document
      # is the root object in the graph it will return self.
      #
      # @example Get the root document in the hierarchy.
      #   document._root
      #
      # @return [ Document ] The root document in the hierarchy.
      def _root
        object = self
        while (object._parent) do object = object._parent; end
        object || self
      end
    end
  end
end
