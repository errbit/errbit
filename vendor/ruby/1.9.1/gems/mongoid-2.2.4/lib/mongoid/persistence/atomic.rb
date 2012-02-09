# encoding: utf-8
require "mongoid/persistence/atomic/operation"
require "mongoid/persistence/atomic/add_to_set"
require "mongoid/persistence/atomic/bit"
require "mongoid/persistence/atomic/inc"
require "mongoid/persistence/atomic/pop"
require "mongoid/persistence/atomic/pull"
require "mongoid/persistence/atomic/pull_all"
require "mongoid/persistence/atomic/push"
require "mongoid/persistence/atomic/push_all"
require "mongoid/persistence/atomic/rename"
require "mongoid/persistence/atomic/sets"
require "mongoid/persistence/atomic/unset"

module Mongoid #:nodoc:
  module Persistence #:nodoc:

    # This module provides the explicit atomic operations helpers on the
    # document itself.
    module Atomic

      # Performs an atomic $addToSet of the provided value on the supplied field.
      # If the field does not exist it will be initialized as an empty array.
      #
      # If the value already exists on the array it will not be added.
      #
      # @example Add only a unique value on the field.
      #   person.add_to_set(:aliases, "Bond")
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Object ] value The value to add.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.0.0
      def add_to_set(field, value, options = {})
        AddToSet.new(self, field, value, options).persist
      end

      # Performs an atomic $bit operation on the field with the provided hash
      # of bitwise ops to execute in order.
      #
      # @example Execute a bitwise and on the field.
      #   person.bit(:age, { :and => 12 })
      #
      # @example Execute a bitwise or on the field.
      #   person.bit(:age, { :or => 12 })
      #
      # @example Execute a chain of bitwise operations.
      #   person.bit(:age, { :and => 10, :or => 12 })
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Hash ] value The bitwise operations to perform.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Integer ] The new value of the field.
      #
      # @since 2.1.0
      def bit(field, value, options = {})
        Bit.new(self, field, value, options).persist
      end

      # Performs an atomic $inc of the provided value on the supplied
      # field. If the field does not exist it will be initialized as
      # the provided value.
      #
      # @example Increment a field.
      #   person.inc(:score, 2)
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Integer ] value The value to increment.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.0.0
      def inc(field, value, options = {})
        Inc.new(self, field, value, options).persist
      end

      # Performs an atomic $pop of the provided value on the supplied
      # field.
      #
      # @example Pop the last value from the array.
      #   person.pop(:aliases, 1)
      #
      # @example Pop the first value from the array.
      #   person.pop(:aliases, -1)
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Integer ] value Whether to pop the first or last.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.1.0
      def pop(field, value, options = {})
        Pop.new(self, field, value, options).persist
      end

      # Performs an atomic $pull of the provided value on the supplied
      # field.
      #
      # @note Support for a $pull with an expression is not yet supported.
      #
      # @example Pull the value from the field.
      #   person.pull(:aliases, "Bond")
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Object ] value The value to pull.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.1.0
      def pull(field, value, options = {})
        Pull.new(self, field, value, options).persist
      end

      # Performs an atomic $pullAll of the provided value on the supplied
      # field. If the field does not exist it will be initialized as an
      # empty array.
      #
      # @example Pull the values from the field.
      #   person.pull_all(:aliases, [ "Bond", "James" ])
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Array<Object> ] value The values to pull.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.0.0
      def pull_all(field, value, options = {})
        PullAll.new(self, field, value, options).persist
      end

      # Performs an atomic $push of the provided value on the supplied field. If
      # the field does not exist it will be initialized as an empty array.
      #
      # @example Push a value on the field.
      #   person.push(:aliases, "Bond")
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Object ] value The value to push.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.0.0
      def push(field, value, options = {})
        Push.new(self, field, value, options).persist
      end

      # Performs an atomic $pushAll of the provided value on the supplied field. If
      # the field does not exist it will be initialized as an empty array.
      #
      # @example Push the values onto the field.
      #   person.push_all(:aliases, [ "Bond", "James" ])
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Array<Object> ] value The values to push.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.1.0
      def push_all(field, value, options = {})
        PushAll.new(self, field, value, options).persist
      end

      # Performs the atomic $rename from the old field to the new field name.
      #
      # @example Rename the field.
      #   person.rename(:age, :years)
      #
      # @param [ Symbol ] field The old field name.
      # @param [ Symbol ] value The new field name.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Object ] The value of the new field.
      #
      # @since 2.1.0
      def rename(field, value, options = {})
        Rename.new(self, field, value, options).persist
      end

      # Performs an atomic $set of the provided value on the supplied
      # field. If the field does not exist it will be initialized as
      # the provided value.
      #
      # @example Set a field.
      #   person.set(:score, 2)
      #
      # @param [ Symbol ] field The name of the field.
      # @param [ Integer ] value The value to set.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ Array<Object> ] The new value of the field.
      #
      # @since 2.1.0
      def set(field, value = nil, options = {})
        Sets.new(self, field, value, options).persist
      end

      # Performs the atomic $unset on the supplied field.
      #
      # @example Remove the field.
      #   person.unset(:age)
      #
      # @param [ Symbol ] field The field name.
      # @param [ Hash ] options The mongo persistence options.
      #
      # @return [ nil ] Always nil.
      #
      # @since 2.1.0
      def unset(field, options = {})
        Unset.new(self, field, 1, options).persist
      end
    end
  end
end
