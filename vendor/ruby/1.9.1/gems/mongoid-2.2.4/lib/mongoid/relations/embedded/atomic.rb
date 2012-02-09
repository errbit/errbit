# encoding: utf-8
require "mongoid/relations/embedded/atomic/operation"
require "mongoid/relations/embedded/atomic/pull"
require "mongoid/relations/embedded/atomic/push_all"
require "mongoid/relations/embedded/atomic/set"
require "mongoid/relations/embedded/atomic/unset"

module Mongoid #:nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:

      # This module provides the ability for calls to be declared atomic.
      module Atomic

        MODIFIERS = {
          :$pull => Pull,
          :$pushAll => PushAll,
          :$set => Set,
          :$unset => Unset
        }

        private

        # Executes a block of commands in an atomic fashion. Mongoid will
        # intercept all database upserts while in this block and combine them
        # into a single database call. When the block concludes the atomic
        # update will occur.
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
        # @example Atomically $set multiple saves.
        #   atomically(:$set) do
        #     address_one.save!
        #     address_two.save!
        #   end
        #
        # @example Atomically $pushAll multiple new docs.
        #   atomically(:$pushAll) do
        #     person.addresses.push([ address_one, address_two ])
        #   end
        #
        # @todo Durran: Move executions to thread local stack.
        #
        # @param [ Symbol ] modifier The atomic modifier to perform.
        # @param [ Proc ] block The block to execute.
        #
        # @return [ Object ] The result of the operation.
        #
        # @since 2.0.0
        def atomically(modifier, &block)
          updater = Threaded.update_consumer(root_class) ||
            Threaded.set_update_consumer(root_class, MODIFIERS[modifier].new)
          count_executions do
            block.call if block
          end.tap do
            if @executions.zero?
              Threaded.set_update_consumer(root_class, nil)
              updater.execute(collection)
            end
          end
        end

        # Execute the block, incrementing the executions before the call and
        # decrementing them after in order to be able to nest blocks within
        # each other.
        #
        # @example Execute and increment.
        #   execute { block.call }
        #
        # @param [ Proc ] block The block to call.
        #
        # @since 2.0.0
        def count_executions(&block)
          @executions ||= 0 and @executions += 1
          block.call.tap do
            @executions -=1
          end
        end
      end
    end
  end
end
