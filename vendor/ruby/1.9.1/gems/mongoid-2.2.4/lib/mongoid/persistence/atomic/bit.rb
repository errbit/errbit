# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This operation is for performing $bit atomic operations against the
      # database.
      class Bit
        include Operation

        # Execute the bitwise operation. This correlates to a $bit in MongoDB.
        #
        # @example Execute the op.
        #   bit.persist
        #
        # @return [ Integer ] The new value.
        #
        # @since 2.1.0
        def persist
          prepare do
            current = document[field]
            return nil unless current
            document[field] = value.inject(current) do |result, (bit, val)|
              result = result & val if bit.to_s == "and"
              result = result | val if bit.to_s == "or"
              result
            end
            document[field].tap do
              collection.update(document.atomic_selector, operation("$bit"), options)
              document.remove_change(field)
            end
          end
        end
      end
    end
  end
end
