# encoding: utf-8
require "mongoid/relations/referenced/batch/insert"

module Mongoid #:nodoc:
  module Relations #:nodoc:
    module Referenced #:nodoc:

      # This module provides the ability for single insert calls to be batch
      # inserted.
      module Batch

        private

        # Executes a number of save calls in a single batch. Mongoid will
        # intercept all database inserts while in this block and combine them
        # into a single database call. When the block concludes the batch
        # insert will occur.
        #
        # Since the collection is accessed through the class it would not be
        # thread safe to give it state so we access the atomic updater via the
        # current thread.
        #
        # @note This operation is not safe when attemping to do illegal updates
        #   for different objects or collections, since the updator is not
        #   scoped on the thread. This is meant for Mongoid internal use only
        #   to keep existing design clean.
        #
        # @example Batch update multiple appends.
        #   batched do
        #     person.posts << [ post_one, post_two, post_three ]
        #   end
        #
        # @todo Durran: Move executions to thread local stack.
        #
        # @param [ Proc ] block The block to execute.
        #
        # @return [ Object ] The result of the operation.
        #
        # @since 2.0.2, batch-relational-insert
        def batched(&block)
          inserter = Threaded.insert ||= Insert.new
          count_executions(&block)
        ensure
          if @executions.zero?
            Threaded.insert = nil
            inserter.execute(collection)
          end
        end

        # Execute the block, incrementing the executions before the call and
        # decrementing them after in order to be able to nest blocks within
        # each other.
        #
        # @todo Durran: Combine common code with embedded atomics.
        #
        # @example Execute and increment.
        #   execute { block.call }
        #
        # @param [ Proc ] block The block to call.
        #
        # @since 2.0.2, batch-relational-insert
        def count_executions
          @executions ||= 0
          @executions += 1
          yield
        ensure
          @executions -=1
        end
      end
    end
  end
end
