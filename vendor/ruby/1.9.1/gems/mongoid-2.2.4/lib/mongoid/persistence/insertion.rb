# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:

    # Contains common logic for insertion operations.
    module Insertion

      # Wrap all the common insertion logic for both root and embedded
      # documents and then yield to the block.
      #
      # @example Execute common insertion logic.
      #   prepare do |doc|
      #     collection.insert({ :field => "value })
      #   end
      #
      # @param [ Proc ] block The block to call.
      #
      # @return [ Document ] The inserted document.
      #
      # @since 2.1.0
      def prepare(&block)
        document.tap do |doc|
          unless validating? && document.invalid?(:create)
            result = doc.run_callbacks(:save) do
              doc.run_callbacks(:create) do
                yield(doc)
                doc.new_record = false
                doc.reset_persisted_children and true
              end
            end

            unless result == false
              doc.move_changes
              Threaded.clear_safety_options!
            end
          end
        end
      end
    end
  end
end
