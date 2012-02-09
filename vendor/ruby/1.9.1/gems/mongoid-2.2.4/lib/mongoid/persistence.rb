# encoding: utf-8
require "mongoid/persistence/atomic"
require "mongoid/persistence/deletion"
require "mongoid/persistence/insertion"
require "mongoid/persistence/modification"
require "mongoid/persistence/operations"

module Mongoid #:nodoc:

  # The persistence module is a mixin to provide database accessor methods for
  # the document. These correspond to the appropriate accessors on a
  # mongo collection and retain the same DSL.
  #
  # @example Sample persistence operations.
  #   document.insert
  #   document.update
  #   document.upsert
  module Persistence
    extend ActiveSupport::Concern
    include Atomic

    # Remove the document from the datbase with callbacks.
    #
    # @example Destroy a document.
    #   document.destroy
    #
    # @param [ Hash ] options Options to pass to destroy.
    #
    # @return [ true, false ] True if successful, false if not.
    def destroy(options = {})
      run_callbacks(:destroy) { remove(options) }
    end

    # Insert a new document into the database. Will return the document
    # itself whether or not the save was successful.
    #
    # @example Insert a document.
    #   document.insert
    #
    # @param [ Hash ] options Options to pass to insert.
    #
    # @return [ Document ] The persisted document.
    def insert(options = {})
      Operations.insert(self, options).persist
    end

    # Remove the document from the datbase.
    #
    # @example Remove the document.
    #   document.remove
    #
    # @param [ Hash ] options Options to pass to remove.
    #
    # @return [ TrueClass ] True.
    def remove(options = {})
      Operations.remove(self, options).persist
    end
    alias :delete :remove

    # Save the document - will perform an insert if the document is new, and
    # update if not. If a validation error occurs an error will get raised.
    #
    # @example Save the document.
    #   document.save!
    #
    # @param [ Hash ] options Options to pass to the save.
    #
    # @return [ true, false ] True if validation passed.
    def save!(options = {})
      unless upsert(options)
        self.class.fail_validate!(self) if errors.any?
        self.class.fail_callback!(self, :save!)
      end
      return true
    end

    # Update the document in the datbase.
    #
    # @example Update an existing document.
    #   document.update
    #
    # @param [ Hash ] options Options to pass to update.
    #
    # @return [ true, false ] True if succeeded, false if not.
    def update(options = {})
      Operations.update(self, options).persist
    end

    # Update a single attribute and persist the entire document.
    # This skips validation but fires the callbacks.
    #
    # @example Update the attribute.
    #   person.update_attribute(:title, "Sir")
    #
    # @param [ Symbol, String ] name The name of the attribute.
    # @param [ Object ] value The new value of the attribute.a
    #
    # @return [ true, false ] True if save was successfull, false if not.
    #
    # @since 2.0.0.rc.6
    def update_attribute(name, value)
      write_attribute(name, value)
      save(:validate => false)
    end

    # Update the document attributes in the datbase.
    #
    # @example Update the document's attributes
    #   document.update_attributes(:title => "Sir")
    #
    # @param [ Hash ] attributes The attributes to update.
    #
    # @return [ true, false ] True if validation passed, false if not.
    def update_attributes(attributes = {})
      write_attributes(attributes); save
    end

    # Update the document attributes in the database and raise an error if
    # validation failed.
    #
    # @example Update the document's attributes.
    #   document.update_attributes(:title => "Sir")
    #
    # @param [ Hash ] attributes The attributes to update.
    #
    # @raise [ Errors::Validations ] If validation failed.
    #
    # @return [ true, false ] True if validation passed.
    def update_attributes!(attributes = {})
      update_attributes(attributes).tap do |result|
        unless result
          self.class.fail_validate!(self) if errors.any?
          self.class.fail_callback!(self, :update_attributes!)
        end
      end
    end

    # Upsert the document - will perform an insert if the document is new, and
    # update if not.
    #
    # @example Upsert the document.
    #   document.upsert
    #
    # @param [ Hash ] options Options to pass to the upsert.
    #
    # @return [ true, false ] True is success, false if not.
    def upsert(options = {})
      if new_record?
        insert(options).persisted?
      else
        update(options)
      end
    end
    alias :save :upsert

    module ClassMethods #:nodoc:

      # Create a new document. This will instantiate a new document and
      # insert it in a single call. Will always return the document
      # whether save passed or not.
      #
      # @example Create a new document.
      #   Person.create(:title => "Mr")
      #
      # @param [ Hash ] attributes The attributes to create with.
      #
      # @return [ Document ] The newly created document.
      def create(attributes = {}, &block)
        creating do
          new(attributes, &block).tap { |doc| doc.save }
        end
      end

      # Create a new document. This will instantiate a new document and
      # insert it in a single call. Will always return the document
      # whether save passed or not, and if validation fails an error will be
      # raise.
      #
      # @example Create a new document.
      #   Person.create!(:title => "Mr")
      #
      # @param [ Hash ] attributes The attributes to create with.
      #
      # @return [ Document ] The newly created document.
      def create!(attributes = {}, &block)
        creating do
          new(attributes, &block).tap do |doc|
            fail_validate!(doc) if doc.insert.errors.any?
            fail_callback!(doc, :create!) if doc.new?
          end
        end
      end

      # Delete all documents given the supplied conditions. If no conditions
      # are passed, the entire collection will be dropped for performance
      # benefits. Does not fire any callbacks.
      #
      # @example Delete matching documents from the collection.
      #   Person.delete_all(:conditions => { :title => "Sir" })
      #
      # @example Delete all documents from the collection.
      #   Person.delete_all
      #
      # @param [ Hash ] conditions Optional conditions to delete by.
      #
      # @return [ Integer ] The number of documents deleted.
      def delete_all(conditions = nil)
        selector = (conditions || {})[:conditions] || {}
        selector.merge!(:_type => name) if hereditary?
        collection.find(selector).count.tap do
          collection.remove(selector, Safety.merge_safety_options)
          Threaded.clear_safety_options!
        end
      end

      # Delete all documents given the supplied conditions. If no conditions
      # are passed, the entire collection will be dropped for performance
      # benefits. Fires the destroy callbacks if conditions were passed.
      #
      # @example Destroy matching documents from the collection.
      #   Person.destroy_all(:conditions => { :title => "Sir" })
      #
      # @example Destroy all documents from the collection.
      #   Person.destroy_all
      #
      # @param [ Hash ] conditions Optional conditions to destroy by.
      #
      # @return [ Integer ] The number of documents destroyed.
      def destroy_all(conditions = {})
        documents = all(conditions)
        documents.count.tap do
          documents.each { |doc| doc.destroy }
        end
      end

      # Raise an error if validation failed.
      #
      # @example Raise the validation error.
      #   Person.fail_validate!(person)
      #
      # @param [ Document ] document The document to fail.
      def fail_validate!(document)
        raise Errors::Validations.new(document)
      end

      # Raise an error if a callback failed.
      #
      # @example Raise the callback error.
      #   Person.fail_callback!(person, :create!)
      #
      # @param [ Document ] document The document to fail.
      # @param [ Symbol ] method The method being called.
      #
      # @since 2.2.0
      def fail_callback!(document, method)
        raise Errors::Callback.new(document.class, method)
      end

      private

      # Execute a block in creating mode.
      #
      # @example Execute in creating mode.
      #   creating do
      #     relation.push(doc)
      #   end
      #
      # @return [ Object ] The return value of the block.
      #
      # @since 2.1.0
      def creating
        Threaded.begin_create
        yield
      ensure
        Threaded.exit_create
      end
    end
  end
end
