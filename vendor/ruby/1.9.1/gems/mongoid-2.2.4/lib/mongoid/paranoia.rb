# encoding: utf-8
module Mongoid #:nodoc:

  # Include this module to get soft deletion of root level documents.
  # This will add a deleted_at field to the +Document+, managed automatically.
  # Potentially incompatible with unique indices. (if collisions with deleted items)
  #
  # @example Make a document paranoid.
  #   class Person
  #     include Mongoid::Document
  #     include Mongoid::Paranoia
  #   end
  module Paranoia
    extend ActiveSupport::Concern

    included do
      field :deleted_at, :type => Time
    end

    # Delete the paranoid +Document+ from the database completely. This will
    # run the destroy callbacks.
    #
    # @example Hard destroy the document.
    #   document.destroy!
    def destroy!
      run_callbacks(:destroy) { delete! }
    end

    # Delete the paranoid +Document+ from the database completely.
    #
    # @example Hard delete the document.
    #   document.delete!
    def delete!
      @destroyed = true
      Persistence::Operations.remove(self).persist
    end

    # Delete the +Document+, will set the deleted_at timestamp and not actually
    # delete it.
    #
    # @example Soft remove the document.
    #   document.remove
    #
    # @param [ Hash ] options The database options.
    #
    # @return [ true ] True.
    def remove(options = {})
      now = Time.now
      collection.update({ :_id => id }, { '$set' => { :deleted_at => now } })
      @attributes["deleted_at"] = now
      true
    end
    alias :delete :remove

    # Determines if this document is destroyed.
    #
    # @example Is the document destroyed?
    #   person.destroyed?

    #
    # @return [ true, false ] If the document is destroyed.
    def destroyed?
      @destroyed || !!deleted_at
    end

    # Restores a previously soft-deleted document. Handles this by removing the
    # deleted_at flag.
    #
    # @example Restore the document from deleted state.
    #   document.restore
    def restore
      collection.update({ :_id => id }, { '$unset' => { :deleted_at => true } })
      @attributes.delete("deleted_at")
    end

    module ClassMethods #:nodoc:

      # Override the default +Criteria+ accessor to only get existing
      # documents. Passes all arguments up to +NamedScope.criteria+
      #
      # @example Override the criteria.
      #   Person.criteria
      #
      # @param [ Array ] args The arguments.
      #
      # @return [ Criteria ] The paranoid compliant criteria.
      def criteria(embedded = false, scoped = true)
        scoped ? super.where(:deleted_at.exists => false) : super
      end

      # Find deleted documents
      #
      # @example Find deleted documents.
      #   Person.deleted
      #   Company.first.employees.deleted
      #   Person.deleted.find("4c188dea7b17235a2a000001").first
      #
      # @return [ Criteria ] The deleted criteria.
      def deleted
        where(:deleted_at.exists => true)
      end
    end
  end
end
