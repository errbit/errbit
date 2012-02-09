# encoding: utf-8
module Mongoid #:nodoc:
  module Dirty #:nodoc:
    extend ActiveSupport::Concern
    include ActiveModel::Dirty

    # Get the changed values for the document. This is a hash with the name of
    # the field as the keys, and the values being an array of previous and
    # current pairs.
    #
    # @example Get the changes.
    #   document.changes
    #
    # @note This is overriding the AM::Dirty implementation to handle
    #   enumerable fields being in the hash when not actually changed.
    #
    # @return [ Hash ] The changed values.
    #
    # @since 2.1.0
    def changes
      {}.tap do |hash|
        changed.each do |name|
          change = attribute_change(name)
          if change
            hash[name] = change if change[0] != change[1]
          end
        end
      end
    end

    # Call this method after save, so the changes can be properly switched.
    #
    # This will unset the memoized children array, set new record to
    # false, set the document as validated, and move the dirty changes.
    #
    # @example Move the changes to previous.
    #   person.move_changes
    #
    # @since 2.1.0
    def move_changes
      @_children = nil
      @previously_changed = changes
      atomic_pulls.clear
      atomic_unsets.clear
      delayed_atomic_sets.clear
      changed_attributes.clear
    end

    # Remove a change from the dirty attributes hash. Used by the single field
    # atomic updators.
    #
    # @example Remove a flagged change.
    #   model.remove_change(:field)
    #
    # @param [ Symbol, String ] name The name of the field.
    #
    # @since 2.1.0
    def remove_change(name)
      changed_attributes.delete(name.to_s)
    end

    # Gets all the new values for each of the changed fields, to be passed to
    # a MongoDB $set modifier.
    #
    # @example Get the setters for the atomic updates.
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.setters # returns { "title" => "Madam" }
    #
    # @return [ Hash ] A +Hash+ of atomic setters.
    def setters
      {}.tap do |modifications|
        changes.each_pair do |field, changes|
          key = embedded? ? "#{atomic_position}.#{field}" : field
          modifications[key] = changes[1]
        end
      end
    end

    private

    # Get the current value for the specified attribute, if the attribute has changed.
    #
    # @note This is overriding the AM::Dirty implementation to read from the mongoid
    #   attributes hash, which may contain a serialized version of the attributes data. It is
    #   necessary to read the serialized version as the changed value, to allow updates to
    #   the MongoDB document to persist correctly. For example, if a DateTime field is updated
    #   it must be persisted as a UTC Time.
    #
    # @return [ Object ] The current value of the field, or nil if no change made.
    #
    # @since 2.1.0
    def attribute_change(attr)
      [changed_attributes[attr], attributes[attr]] if attribute_changed?(attr)
    end

    # Determine if a specific attribute has changed.
    #
    # @note Overriding AM::Dirty once again since their implementation is not
    #   friendly to fields that can be changed in place.
    #
    # @param [ String ] attr The name of the attribute.
    #
    # @return [ true, false ] Whether the attribute has changed.
    #
    # @since 2.1.6
    def attribute_changed?(attr)
      return false unless changed_attributes.include?(attr)
      changed_attributes[attr] != attributes[attr]
    end
  end
end
