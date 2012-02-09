# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Operations #:nodoc:
      module Embedded #:nodoc:

        # Remove is a persistence command responsible for deleting a document from
        # the database.
        #
        # The underlying query resembles the following MongoDB query:
        #
        #   collection.remove(
        #     { "_id" : 1 },
        #     false
        #   );
        class Remove
          include Deletion, Operations

          # Remove the document from the database. If the parent is a new record,
          # it will get removed in Ruby only. If the parent is not a new record
          # then either an $unset or $set will occur, depending if it's an
          # embeds_one or embeds_many.
          #
          # @example Remove an embedded document.
          #   RemoveEmbedded.persist
          #
          # @return [ true ] Always true.
          def persist
            prepare do |doc|
              parent.remove_child(doc) if notifying_parent?
              if parent.persisted?
                collection.update(parent.atomic_selector, deletes, options)
              end
            end
          end
        end
      end
    end
  end
end
