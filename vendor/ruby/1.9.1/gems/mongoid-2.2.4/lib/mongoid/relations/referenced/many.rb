# encoding: utf-8
module Mongoid #:nodoc:
  module Relations #:nodoc:
    module Referenced #:nodoc:

      # This class defines the behaviour for all relations that are a
      # one-to-many between documents in different collections.
      class Many < Relations::Many
        include Batch

        delegate :count, :to => :criteria
        delegate :first, :in_memory, :last, :reset, :uniq, :to => :target

        # Appends a document or array of documents to the relation. Will set
        # the parent and update the index in the process.
        #
        # @example Append a document.
        #   person.posts << post
        #
        # @example Push a document.
        #   person.posts.push(post)
        #
        # @example Concat with other documents.
        #   person.posts.concat([ post_one, post_two ])
        #
        # @param [ Document, Array<Document> ] *args Any number of documents.
        #
        # @return [ Array<Document> ] The loaded docs.
        #
        # @since 2.0.0.beta.1
        def <<(*args)
          batched do
            args.flatten.each do |doc|
              next unless doc
              append(doc)
              doc.save if persistable? && !doc.validated?
            end
          end
        end
        alias :concat :<<
        alias :push :<<

        # Build a new document from the attributes and append it to this
        # relation without saving.
        #
        # @example Build a new document on the relation.
        #   person.posts.build(:title => "A new post")
        #
        # @param [ Hash ] attributes The attributes of the new document.
        # @param [ Class ] type The optional subclass to build.
        #
        # @return [ Document ] The new document.
        #
        # @since 2.0.0.beta.1
        def build(attributes = {}, type = nil)
          Factory.build(type || klass, attributes).tap do |doc|
            append(doc)
            yield(doc) if block_given?
          end
        end
        alias :new :build

        # Creates a new document on the references many relation. This will
        # save the document if the parent has been persisted.
        #
        # @example Create and save the new document.
        #   person.posts.create(:text => "Testing")
        #
        # @param [ Hash ] attributes The attributes to create with.
        # @param [ Class ] type The optional type of document to create.
        #
        # @return [ Document ] The newly created document.
        #
        # @since 2.0.0.beta.1
        def create(attributes = nil, type = nil, &block)
          build(attributes, type, &block).tap do |doc|
            base.persisted? ? doc.save : raise_unsaved(doc)
          end
        end

        # Creates a new document on the references many relation. This will
        # save the document if the parent has been persisted and will raise an
        # error if validation fails.
        #
        # @example Create and save the new document.
        #   person.posts.create!(:text => "Testing")
        #
        # @param [ Hash ] attributes The attributes to create with.
        # @param [ Class ] type The optional type of document to create.
        #
        # @raise [ Errors::Validations ] If validation failed.
        #
        # @return [ Document ] The newly created document.
        #
        # @since 2.0.0.beta.1
        def create!(attributes = nil, type = nil, &block)
          build(attributes, type, &block).tap do |doc|
            base.persisted? ? doc.save! : raise_unsaved(doc)
          end
        end

        # Delete the document from the relation. This will set the foreign key
        # on the document to nil. If the dependent options on the relation are
        # :delete or :destroy the appropriate removal will occur.
        #
        # @example Delete the document.
        #   person.posts.delete(post)
        #
        # @param [ Document ] document The document to remove.
        #
        # @return [ Document ] The matching document.
        #
        # @since 2.1.0
        def delete(document)
          target.delete(document) do |doc|
            if doc
              unbind_one(doc)
              cascade!(doc)
            end
          end
        end

        # Deletes all related documents from the database given the supplied
        # conditions.
        #
        # @example Delete all documents in the relation.
        #   person.posts.delete_all
        #
        # @example Conditonally delete all documents in the relation.
        #   person.posts.delete_all(:conditions => { :title => "Testing" })
        #
        # @param [ Hash ] conditions Optional conditions to delete with.
        #
        # @return [ Integer ] The number of documents deleted.
        #
        # @since 2.0.0.beta.1
        def delete_all(conditions = nil)
          remove_all(conditions, :delete_all)
        end

        # Destroys all related documents from the database given the supplied
        # conditions.
        #
        # @example Destroy all documents in the relation.
        #   person.posts.destroy_all
        #
        # @example Conditonally destroy all documents in the relation.
        #   person.posts.destroy_all(:conditions => { :title => "Testing" })
        #
        # @param [ Hash ] conditions Optional conditions to destroy with.
        #
        # @return [ Integer ] The number of documents destroyd.
        #
        # @since 2.0.0.beta.1
        def destroy_all(conditions = nil)
          remove_all(conditions, :destroy_all)
        end

        # Iterate over each document in the relation and yield to the provided
        # block.
        #
        # @note This will load the entire relation into memory.
        #
        # @example Iterate over the documents.
        #   person.posts.each do |post|
        #     post.save
        #   end
        #
        # @return [ Array<Document> ] The loaded docs.
        #
        # @since 2.1.0
        def each
          target.each { |doc| yield(doc) if block_given? }
        end

        # Find the matchind document on the association, either based on id or
        # conditions.
        #
        # @example Find by an id.
        #   person.posts.find(BSON::ObjectId.new)
        #
        # @example Find by multiple ids.
        #   person.posts.find([ BSON::ObjectId.new, BSON::ObjectId.new ])
        #
        # @example Conditionally find all matching documents.
        #   person.posts.find(:all, :conditions => { :title => "Sir" })
        #
        # @example Conditionally find the first document.
        #   person.posts.find(:first, :conditions => { :title => "Sir" })
        #
        # @example Conditionally find the last document.
        #   person.posts.find(:last, :conditions => { :title => "Sir" })
        #
        # @param [ Symbol, BSON::ObjectId, Array<BSON::ObjectId> ] arg The
        #   argument to search with.
        # @param [ Hash ] options The options to search with.
        #
        # @return [ Document, Criteria ] The matching document(s).
        #
        # @since 2.0.0.beta.1
        def find(*args)
          criteria.find(*args)
        end

        # Instantiate a new references_many relation. Will set the foreign key
        # and the base on the inverse object.
        #
        # @example Create the new relation.
        #   Referenced::Many.new(base, target, metadata)
        #
        # @param [ Document ] base The document this relation hangs off of.
        # @param [ Array<Document> ] target The target of the relation.
        # @param [ Metadata ] metadata The relation's metadata.
        #
        # @since 2.0.0.beta.1
        def initialize(base, target, metadata)
          init(base, Targets::Enumerable.new(target), metadata) do
            raise_mixed if klass.embedded?
          end
        end

        # Removes all associations between the base document and the target
        # documents by deleting the foreign keys and the references, orphaning
        # the target documents in the process.
        #
        # @example Nullify the relation.
        #   person.posts.nullify
        #
        # @since 2.0.0.rc.1
        def nullify
          criteria.update(metadata.foreign_key => nil)
          target.clear do |doc|
            unbind_one(doc)
          end
        end
        alias :nullify_all :nullify

        # Clear the relation. Will delete the documents from the db if they are
        # already persisted.
        #
        # @example Clear the relation.
        #   person.posts.clear
        #
        # @return [ Many ] The relation emptied.
        #
        # @since 2.0.0.beta.1
        def purge
          unless metadata.destructive?
            nullify
          else
            criteria.delete_all
            target.clear do |doc|
              unbind_one(doc)
              doc.destroyed = true
            end
          end
        end
        alias :clear :purge

        # Substitutes the supplied target documents for the existing documents
        # in the relation. If the new target is nil, perform the necessary
        # deletion.
        #
        # @example Replace the relation.
        #   person.posts.substitute([ new_post ])
        #
        # @param [ Array<Document> ] replacement The replacement target.
        #
        # @return [ Many ] The relation.
        #
        # @since 2.0.0.rc.1
        def substitute(replacement)
          tap do |proxy|
            if replacement != proxy.in_memory
              proxy.purge
              proxy.push(replacement.compact) if replacement
            end
          end
        end

        private

        # Appends the document to the target array, updating the index on the
        # document at the same time.
        #
        # @example Append the document to the relation.
        #   relation.append(document)
        #
        # @param [ Document ] document The document to append to the target.
        #
        # @since 2.0.0.rc.1
        def append(document)
          target.push(document)
          characterize_one(document)
          bind_one(document)
        end

        # Instantiate the binding associated with this relation.
        #
        # @example Get the binding.
        #   relation.binding([ address ])
        #
        # @param [ Array<Document> ] new_target The new documents to bind with.
        #
        # @return [ Binding ] The binding.
        #
        # @since 2.0.0.rc.1
        def binding
          Bindings::Referenced::Many.new(base, target, metadata)
        end

        # Get the collection of the relation in question.
        #
        # @example Get the collection of the relation.
        #   relation.collection
        #
        # @return [ Collection ] The collection of the relation.
        #
        # @since 2.0.2
        def collection
          klass.collection
        end

        # Get the value for the foreign key in convertable or unconvertable
        # form.
        #
        # @todo Durran: Find a common place for this.
        #
        # @example Get the value.
        #   relation.convertable
        #
        # @return [ String, BSON::ObjectId ] The string or object id.
        #
        # @since 2.0.2
        def convertable
          inverse = metadata.inverse_klass
          if inverse.using_object_ids? || base.id.is_a?(BSON::ObjectId)
            base.id
          else
            base.id.tap do |id|
              id.unconvertable_to_bson = true if id.is_a?(String)
            end
          end
        end

        # Returns the criteria object for the target class with its documents set
        # to target.
        #
        # @example Get a criteria for the relation.
        #   relation.criteria
        #
        # @return [ Criteria ] A new criteria.
        #
        # @since 2.0.0.beta.1
        def criteria
          Many.criteria(metadata, convertable)
        end

        # Perform the necessary cascade operations for documents that just got
        # deleted or nullified.
        #
        # @example Cascade the change.
        #   relation.cascade!(document)
        #
        # @param [ Document ] document The document to cascade on.
        #
        # @return [ true, false ] If the metadata is destructive.
        #
        # @since 2.1.0
        def cascade!(document)
          if persistable?
            if metadata.destructive?
              document.send(metadata.dependent)
            else
              document.save
            end
          end
        end

        # If the target array does not respond to the supplied method then try to
        # find a named scope or criteria on the class and send the call there.
        #
        # If the method exists on the array, use the default proxy behavior.
        #
        # @param [ Symbol, String ] name The name of the method.
        # @param [ Array ] args The method args
        # @param [ Proc ] block Optional block to pass.
        #
        # @return [ Criteria, Object ] A Criteria or return value from the target.
        #
        # @since 2.0.0.beta.1
        def method_missing(name, *args, &block)
          if target.respond_to?(name)
            target.send(name, *args, &block)
          else
            klass.send(:with_scope, criteria) do
              criteria.send(name, *args, &block)
            end
          end
        end

        # Are we able to persist this relation?
        #
        # @example Can we persist the relation?
        #   relation.persistable?
        #
        # @return [ true, false ] If the relation is persistable.
        #
        # @since 2.1.0
        def persistable?
          base.persisted? && !binding? && !building?
        end

        # Deletes all related documents from the database given the supplied
        # conditions.
        #
        # @example Delete all documents in the relation.
        #   person.posts.delete_all
        #
        # @example Conditonally delete all documents in the relation.
        #   person.posts.delete_all(:conditions => { :title => "Testing" })
        #
        # @param [ Hash ] conditions Optional conditions to delete with.
        # @param [ Symbol ] The deletion method to call.
        #
        # @return [ Integer ] The number of documents deleted.
        #
        # @since 2.1.0
        def remove_all(conditions = nil, method = :delete_all)
          selector = (conditions || {})[:conditions] || {}
          klass.send(method, :conditions => selector.merge!(criteria.selector)).tap do
            target.delete_if do |doc|
              if doc.matches?(selector)
                unbind_one(doc) and true
              end
            end
          end
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Referenced::Many.builder(meta, object)
          #
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build
          #   with.
          #
          # @return [ Builder ] A new builder object.
          #
          # @since 2.0.0.rc.1
          def builder(meta, object, loading = false)
            Builders::Referenced::Many.new(meta, object || [], loading)
          end

          # Get the standard criteria used for querying this relation.
          #
          # @example Get the criteria.
          #   Proxy.criteria(meta, id, Model)
          #
          # @param [ Metadata ] metadata The metadata.
          # @param [ Object ] object The value of the foreign key.
          # @param [ Class ] type The optional type.
          #
          # @return [ Criteria ] The criteria.
          #
          # @since 2.1.0
          def criteria(metadata, object, type = nil)
            metadata.klass.where(metadata.foreign_key => object)
          end

          # Eager load the relation based on the criteria.
          #
          # @example Eager load the criteria.
          #   Proxy.eager_load(metadata, criteria)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Criteria ] criteria The criteria being used.
          #
          # @return [ Criteria ] The criteria to eager load the relation.
          #
          # @since 2.2.0
          def eager_load(metadata, criteria)
            klass, foreign_key = metadata.klass, metadata.foreign_key
            klass.any_in(foreign_key => criteria.load_ids("_id").uniq).each do |doc|
              IdentityMap.set_many(doc, foreign_key => doc.send(foreign_key))
            end
          end

          # Returns true if the relation is an embedded one. In this case
          # always false.
          #
          # @example Is this relation embedded?
          #   Referenced::Many.embedded?
          #
          # @return [ false ] Always false.
          #
          # @since 2.0.0.rc.1
          def embedded?
            false
          end

          # Get the default value for the foreign key.
          #
          # @example Get the default.
          #   Referenced::Many.foreign_key_default
          #
          # @return [ nil ] Always nil.
          #
          # @since 2.0.0.rc.1
          def foreign_key_default
            nil
          end

          # Returns the suffix of the foreign key field, either "_id" or "_ids".
          #
          # @example Get the suffix for the foreign key.
          #   Referenced::Many.foreign_key_suffix
          #
          # @return [ String ] "_id"
          #
          # @since 2.0.0.rc.1
          def foreign_key_suffix
            "_id"
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # @example Get the macro.
          #   Referenced::Many.macro
          #
          # @return [ Symbol ] :references_many
          def macro
            :references_many
          end

          # Return the nested builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the nested builder.
          #   Referenced::Many.builder(attributes, options)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Hash ] attributes The attributes to build with.
          # @param [ Hash ] options The options for the builder.
          #
          # @option options [ true, false ] :allow_destroy Can documents be
          #   deleted?
          # @option options [ Integer ] :limit Max number of documents to
          #   create at once.
          # @option options [ Proc, Symbol ] :reject_if If documents match this
          #   option then they are ignored.
          # @option options [ true, false ] :update_only Only existing documents
          #   can be modified.
          #
          # @return [ NestedBuilder ] A newly instantiated nested builder object.
          #
          # @since 2.0.0.rc.1
          def nested_builder(metadata, attributes, options)
            Builders::NestedAttributes::Many.new(metadata, attributes, options)
          end

          # Get the path calculator for the supplied document.
          #
          # @example Get the path calculator.
          #   Proxy.path(document)
          #
          # @param [ Document ] document The document to calculate on.
          #
          # @return [ Root ] The root atomic path calculator.
          #
          # @since 2.1.0
          def path(document)
            Mongoid::Atomic::Paths::Root.new(document)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # @example Does this relation store a foreign key?
          #   Referenced::Many.stores_foreign_key?
          #
          # @return [ false ] Always false.
          #
          # @since 2.0.0.rc.1
          def stores_foreign_key?
            false
          end

          # Get the valid options allowed with this relation.
          #
          # @example Get the valid options.
          #   Relation.valid_options
          #
          # @return [ Array<Symbol> ] The valid options.
          #
          # @since 2.1.0
          def valid_options
            [ :as, :autosave, :dependent, :foreign_key, :order ]
          end

          # Get the default validation setting for the relation. Determines if
          # by default a validates associated will occur.
          #
          # @example Get the validation default.
          #   Proxy.validation_default
          #
          # @return [ true, false ] The validation default.
          #
          # @since 2.1.9
          def validation_default
            true
          end
        end
      end
    end
  end
end
