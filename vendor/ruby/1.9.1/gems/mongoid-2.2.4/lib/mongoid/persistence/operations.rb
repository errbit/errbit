# encoding: utf-8
require "mongoid/persistence/operations/insert"
require "mongoid/persistence/operations/remove"
require "mongoid/persistence/operations/update"
require "mongoid/persistence/operations/embedded/insert"
require "mongoid/persistence/operations/embedded/remove"

module Mongoid #:nodoc:
  module Persistence #:nodoc:

    # Persistence operations include this module to get basic functionality
    # on initialization.
    module Operations

      attr_reader :conflicts, :document

      # Get the collection we should be persisting to.
      #
      # @example Get the collection.
      #   operation.collection
      #
      # @return [ Collection ] The collection to persist to.
      #
      # @since 2.1.0
      def collection
        @collection ||= document._root.collection
      end

      # Get the atomic delete operations for embedded documents.
      #
      # @example Get the atomic deletes.
      #   operation.deletes
      #
      # @return [ Hash ] The atomic delete selector.
      #
      # @since 2.1.0
      def deletes
        { document.atomic_delete_modifier =>
          { document.atomic_path =>
            document._index ? { "_id" => document.id } : true } }
      end

      # Instantiate the new persistence operation.
      #
      # @example Create the operation.
      #   Operation.new(document, { :safe => true }, { "field" => "value" })
      #
      # @param [ Document ] document The document to persist.
      # @param [ Hash ] options The persistence options.
      #
      # @since 2.1.0
      def initialize(document, options = {})
        @document, @options = document, options
      end

      # Get the atomic insert for embedded documents, either a push or set.
      #
      # @example Get the inserts.
      #   operation.inserts
      #
      # @return [ Hash ] The insert ops.
      #
      # @since 2.1.0
      def inserts
        { document.atomic_insert_modifier =>
          { document.atomic_position => document.as_document } }
      end

      # Should the parent document (in the case of embedded persistence) be
      # notified of the child deletion. This is used when calling delete from
      # the associations themselves.
      #
      # @example Should the parent be notified?
      #   operation.notifying_parent?
      #
      # @return [ true, false ] If the parent should be notified.
      #
      # @since 2.1.0
      def notifying_parent?
        @notifying_parent ||= !@options.delete(:suppress)
      end

      # Get all the options that will be sent to the database. Right now this
      # is only safe mode opts.
      #
      # @example Get the options hash.
      #   operation.options
      #
      # @return [ Hash ] The options for the database.
      #
      # @since 2.1.0
      def options
        Safety.merge_safety_options(@options)
      end

      # Get the parent of the provided document.
      #
      # @example Get the parent.
      #   operation.parent
      #
      # @return [ Document ] The parent document.
      #
      # @since 2.1.0
      def parent
        document._parent
      end

      # Get the atomic selector for the document.
      #
      # @example Get the selector.
      #   operation.selector.
      #
      # @return [ Hash ] The mongodb selector.
      #
      # @since 2.1.0
      def selector
        @selector ||= document.atomic_selector
      end

      # Get the atomic updates for the document without the conflicting
      # modifications.
      #
      # @example Get the atomic updates.
      #   operation.updates
      #
      # @return [ Hash ] The updates sans conflicting mods.
      #
      # @since 2.1.0
      def updates
        @updates ||= init_updates
      end

      # Should we be running validations on this persistence operation?
      # Defaults to true.
      #
      # @example Run validations?
      #   operation.validating?
      #
      # @return [ true, false ] If we run validations.
      #
      # @since 2.1.0
      def validating?
        @validating ||= @options[:validate].nil? ? true : @options[:validate]
      end

      private

      # Initialize the atomic updates and conflicting modifications.
      #
      # @example Initialize the updates.
      #   operation.init_updates
      #
      # @return [ Hash ] The atomic updates.
      #
      # @since 2.1.0
      def init_updates
        document.atomic_updates.tap do |updates|
          @conflicts = updates.delete(:conflicts) || {}
        end
      end

      class << self

        # Get the appropriate removal operation based on the document.
        #
        # @example Get the deletion operation.
        #   Operations.remove(doc, options)
        #
        # @param [ Document ] doc The document to persist.
        # @param [ Hash ] options The persistence options.
        #
        # @return [ Operations ] The operation.
        #
        # @since 2.1.0
        def remove(doc, options = {})
          (doc.embedded? ? Embedded::Remove : Remove).new(doc, options)
        end

        # Get the appropriate insertion operation based on the document.
        #
        # @example Get the insertion operation.
        #   Operations.insert(doc, options)
        #
        # @param [ Document ] doc The document to persist.
        # @param [ Hash ] options The persistence options.
        #
        # @return [ Operations ] The operation.
        #
        # @since 2.1.0
        def insert(doc, options = {})
          (doc.embedded? ? Embedded::Insert : Insert).new(doc, options)
        end

        # Get the appropriate update operation based on the document.
        #
        # @example Get the update operation.
        #   Operations.update(doc, options)
        #
        # @param [ Document ] doc The document to persist.
        # @param [ Hash ] options The persistence options.
        #
        # @return [ Operations ] The operation.
        #
        # @since 2.1.0
        def update(doc, options = {})
          Update.new(doc, options)
        end
      end
    end
  end
end
