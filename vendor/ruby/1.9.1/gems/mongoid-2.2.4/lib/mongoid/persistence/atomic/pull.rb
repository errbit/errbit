# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides the ability to perform an explicit $pull
      # modification on a specific field.
      class Pull
        include Operation

        # Sends the atomic $pull operation to the database.
        #
        # @example Persist the new values.
        #   pull.persist
        #
        # @return [ Object ] The new array value.
        #
        # @since 2.1.0
        def persist
          prepare do
            if document[field]
              values = document.send(field)
              values.delete(value)
              values.tap do
                collection.update(document.atomic_selector, operation("$pull"), options)
                document.remove_change(field) if document.persisted?
              end
            end
          end
        end
      end
    end
  end
end
