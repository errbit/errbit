# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This module handles the behaviour for synchronizing foreign keys between
    # both sides of a many to many relations.
    module Synchronization
      extend ActiveSupport::Concern

      # Is the document able to be synced on the inverse side? This is only if
      # the key has changed and the relation bindings have not been run.
      #
      # @example Are the foreign keys syncable?
      #   document.syncable?(metadata)
      #
      # @param [ Metadata ] metadata The relation metadata.
      #
      # @return [ true, false ] If we can sync.
      #
      # @since 2.1.0
      def syncable?(metadata)
        !synced?(metadata.foreign_key) && send(metadata.foreign_key_check)
      end

      # Get the synced foreign keys.
      #
      # @example Get the synced foreign keys.
      #   document.synced
      #
      # @return [ Hash ] The synced foreign keys.
      #
      # @since 2.1.0
      def synced
        @synced ||= {}
      end

      # Has the document been synced for the foreign key?
      #
      # @todo Change the sync to be key based.
      #
      # @example Has the document been synced?
      #   document.synced?
      #
      # @param [ String ] foreign_key The foreign key.
      #
      # @return [ true, false ] If we can sync.
      #
      # @since 2.1.0
      def synced?(foreign_key)
        !!synced[foreign_key]
      end

      # Update the inverse keys on destroy.
      #
      # @example Update the inverse keys.
      #   document.remove_inverse_keys(metadata)
      #
      # @param [ Metadata ] meta The document metadata.
      #
      # @return [ Object ] The updated values.
      #
      # @since 2.2.1
      def remove_inverse_keys(meta)
        meta.criteria(send(meta.foreign_key)).pull(meta.inverse_foreign_key, id)
      end

      # Update the inverse keys for the relation.
      #
      # @example Update the inverse keys
      #   document.update_inverse_keys(metadata)
      #
      # @param [ Metadata ] meta The document metadata.
      #
      # @return [ Object ] The updated values.
      #
      # @since 2.1.0
      def update_inverse_keys(meta)
        return unless changes.has_key?(meta.foreign_key)
        old, new = changes[meta.foreign_key]
        adds, subs = new - old, old - new
        meta.criteria(adds).add_to_set(meta.inverse_foreign_key, id) unless adds.empty?
        meta.criteria(subs).pull(meta.inverse_foreign_key, id) unless subs.empty?
      end

      module ClassMethods #:nodoc:

        # Set up the syncing of many to many foreign keys.
        #
        # @example Set up the syncing.
        #   Person.synced(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @since 2.1.0
        def synced(metadata)
          unless metadata.forced_nil_inverse?
            synced_save(metadata)
            synced_destroy(metadata)
          end
        end

        private

        # Set up the sync of inverse keys that needs to happen on a save.
        #
        # If the foreign key field has changed and the document is not
        # synced, $addToSet the new ids, $pull the ones no longer in the
        # array from the inverse side.
        #
        # @example Set up the save syncing.
        #   Person.synced_save(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @return [ Class ] The class getting set up.
        #
        # @since 2.1.0
        def synced_save(metadata)
          tap do
            set_callback(
              :save,
              :after,
              :if => lambda { |doc| doc.syncable?(metadata) }
            ) do |doc|
              doc.update_inverse_keys(metadata)
            end
          end
        end

        # Set up the sync of inverse keys that needs to happen on a destroy.
        #
        # @example Set up the destroy syncing.
        #   Person.synced_destroy(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @return [ Class ] The class getting set up.
        #
        # @since 2.2.1
        def synced_destroy(metadata)
          tap do
            set_callback(
              :destroy,
              :after
            ) do |doc|
              doc.remove_inverse_keys(metadata)
            end
          end
        end
      end
    end
  end
end
