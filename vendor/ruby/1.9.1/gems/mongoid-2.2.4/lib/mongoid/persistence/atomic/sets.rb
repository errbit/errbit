# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides atomic $set behaviour.
      class Sets
        include Operation

        # Sends the atomic $set operation to the database.
        #
        # @example Persist the new values.
        #   set.persist
        #
        # @return [ Object ] The new field value.
        #
        # @ssete 2.0.0
        def persist
          prepare do
            value ? document[field] = value : @value = document[field]
            document[field].tap do
              collection.update(document.atomic_selector, operation("$set"), options)
              document.remove_change(field)
            end
          end
        end
      end
    end
  end
end
