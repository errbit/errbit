# encoding: utf-8
module Mongoid #:nodoc:
  module Atomic #:nodoc:

    # This class contains the logic for supporting atomic operations against the
    # database.
    class Modifiers < Hash

      # Adds pull modifiers to the modifiers hash.
      #
      # @example Add pull operations.
      #   modifiers.pull({ "addresses" => { "street" => "Bond" }})
      #
      # @param [ Hash ] modifications The pull modifiers.
      #
      # @since 2.2.0
      def pull(modifications)
        modifications.each_pair do |field, value|
          add_operation(pulls, field, value)
          pull_fields << field.split(".", 2)[0]
        end
      end

      # Adds push modifiers to the modifiers hash.
      #
      # @example Add push operations.
      #   modifiers.push({ "addresses" => { "street" => "Bond" }})
      #
      # @param [ Hash ] modifications The push modifiers.
      #
      # @since 2.1.0
      def push(modifications)
        modifications.each_pair do |field, value|
          mods = push_conflict?(field) ? conflicting_pushes : pushes
          add_operation(mods, field, Array.wrap(value))
        end
      end

      # Adds set operations to the modifiers hash.
      #
      # @example Add set operations.
      #   modifiers.set({ "title" => "sir" })
      #
      # @param [ Hash ] modifications The set modifiers.
      #
      # @since 2.1.0
      def set(modifications)
        modifications.each_pair do |field, value|
          next if field == "_id"
          mods = set_conflict?(field) ? conflicting_sets : sets
          add_operation(mods, field, value)
          set_fields << field.split(".", 2)[0]
        end
      end

      # Adds unset operations to the modifiers hash.
      #
      # @example Add unset operations.
      #   modifiers.unset([ "addresses" ])
      #
      # @param [ Array<String> ] modifications The unset relation names.
      #
      # @since 2.2.0
      def unset(modifications)
        modifications.each do |field|
          unsets.update(field => true)
        end
      end

      private

      # Add the operation to the modifications, either appending or creating a
      # new one.
      #
      # @example Add the operation.
      #   modifications.add_operation(mods, field, value)
      #
      # @param [ Hash ] mods The modifications.
      # @param [ String ] field The field.
      # @param [ Hash ] value The atomic op.
      #
      # @since 2.2.0
      def add_operation(mods, field, value)
        if mods.has_key?(field)
          value.each do |val|
            mods[field].push(val)
          end
        else
          mods[field] = value
        end
      end

      # Is the operation going to be a conflict for a $set?
      #
      # @example Is this a conflict for a set?
      #   modifiers.set_conflict?(field)
      #
      # @param [ String ] field The field.
      #
      # @return [ true, false ] If this field is a conflict.
      #
      # @since 2.2.0
      def set_conflict?(field)
        pull_fields.include?(field.split(".", 2)[0])
      end

      # Is the operation going to be a conflict for a $push?
      #
      # @example Is this a conflict for a push?
      #   modifiers.push_conflict?(field)
      #
      # @param [ String ] field The field.
      #
      # @return [ true, false ] If this field is a conflict.
      #
      # @since 2.2.0
      def push_conflict?(field)
        name = field.split(".", 2)[0]
        set_fields.include?(name) || pull_fields.include?(name)
      end

      # Get the conflicting pull modifications.
      #
      # @example Get the conflicting pulls.
      #   modifiers.conflicting_pulls
      #
      # @return [ Hash ] The conflicting pull operations.
      #
      # @since 2.2.0
      def conflicting_pulls
        conflicts["$pullAll"] ||= {}
      end

      # Get the conflicting push modifications.
      #
      # @example Get the conflicting pushs.
      #   modifiers.conflicting_pushs
      #
      # @return [ Hash ] The conflicting push operations.
      #
      # @since 2.2.0
      def conflicting_pushes
        conflicts["$pushAll"] ||= {}
      end

      # Get the conflicting set modifications.
      #
      # @example Get the conflicting sets.
      #   modifiers.conflicting_sets
      #
      # @return [ Hash ] The conflicting set operations.
      #
      # @since 2.2.0
      def conflicting_sets
        conflicts["$set"] ||= {}
      end

      # Get the push operations that would have conflicted with the sets.
      #
      # @example Get the conflicts.
      #   modifiers.conflicts
      #
      # @return [ Hash ] The conflicting modifications.
      #
      # @since 2.1.0
      def conflicts
        self[:conflicts] ||= {}
      end

      # Get the names of the fields that need to be pulled.
      #
      # @example Get the pull fields.
      #   modifiers.pull_fields
      #
      # @return [ Array<String> ] The pull fields.
      #
      # @since 2.2.0
      def pull_fields
        @pull_fields ||= []
      end

      # Get the names of the fields that need to be set.
      #
      # @example Get the set fields.
      #   modifiers.set_fields
      #
      # @return [ Array<String> ] The set fields.
      #
      # @since 2.2.0
      def set_fields
        @set_fields ||= []
      end

      # Get the $pullAll operations or intialize a new one.
      #
      # @example Get the $pullAll operations.
      #   modifiers.pulles
      #
      # @return [ Hash ] The $pullAll operations.
      #
      # @since 2.1.0
      def pulls
        self["$pullAll"] ||= {}
      end

      # Get the $pushAll operations or intialize a new one.
      #
      # @example Get the $pushAll operations.
      #   modifiers.pushes
      #
      # @return [ Hash ] The $pushAll operations.
      #
      # @since 2.1.0
      def pushes
        self["$pushAll"] ||= {}
      end

      # Get the $set operations or intialize a new one.
      #
      # @example Get the $set operations.
      #   modifiers.sets
      #
      # @return [ Hash ] The $set operations.
      #
      # @since 2.1.0
      def sets
        self["$set"] ||= {}
      end

      # Get the $unset operations or initialize a new one.
      #
      # @example Get the $unset operations.
      #   modifiers.unsets
      #
      # @return [ Hash ] The $unset operations.
      #
      # @since 2.2.0
      def unsets
        self["$unset"] ||= {}
      end
    end
  end
end
