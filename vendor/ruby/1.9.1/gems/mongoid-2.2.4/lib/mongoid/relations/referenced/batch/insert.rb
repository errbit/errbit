# encoding: utf-8
module Mongoid #:nodoc:
  module Relations #:nodoc:
    module Referenced #:nodoc:
      module Batch #:nodoc:

        # Handles all the batch insert collection.
        class Insert
          attr_accessor :documents, :options

          # Consumes an execution that was supposed to hit the database, but is
          # now being deferred to later in favor of a single batch insert.
          #
          # @example Consume the operation.
          #   set.consume({ "field" => "value" }, { :safe => true })
          #
          # @param [ Hash ] document The document to collect.
          # @param [ Hash ] options The persistence options.
          #
          # @option options [ true, false ] :safe Persist in safe mode.
          #
          # @since 2.0.2, batch-relational-insert
          def consume(document, options = {})
            @consumed, @options = true, options
            (@documents ||= []).push(document)
          end

          # Has this operation consumed any executions?
          #
          # @example Is this consumed?
          #   insert.consumed?
          #
          # @return [ true, false ] If the operation has consumed anything.
          #
          # @since 2.0.2, batch-relational-insert
          def consumed?
            !!@consumed
          end

          # Execute the batch insert operation on the collection.
          #
          # @example Execute the operation.
          #   insert.execute(collection)
          #
          # @param [ Collection ] collection The root collection.
          #
          # @since 2.0.2, batch-relational-insert
          def execute(collection)
            if collection && consumed?
              collection.insert(documents, options)
            end
          end
        end
      end
    end
  end
end
