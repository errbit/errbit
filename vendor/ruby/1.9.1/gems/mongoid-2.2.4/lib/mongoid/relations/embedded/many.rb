# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:

      # This class handles the behaviour for a document that embeds many other
      # documents within in it as an array.
      class Many < Relations::Many
        include Atomic

        # Appends a document or array of documents to the relation. Will set
        # the parent and update the index in the process.
        #
        # @example Append a document.
        #   person.addresses << address
        #
        # @example Push a document.
        #   person.addresses.push(address)
        #
        # @example Concat with other documents.
        #   person.addresses.concat([ address_one, address_two ])
        #
        # @param [ Document, Array<Document> ] *args Any number of documents.
        def <<(*args)
          atomically(:$pushAll) do
            args.flatten.each do |doc|
              next unless doc
              append(doc)
              doc.save if persistable? && !assigning?
            end
          end
        end
        alias :concat :<<
        alias :push :<<

        # Builds a new document in the relation and appends it to the target.
        # Takes an optional type if you want to specify a subclass.
        #
        # @example Build a new document on the relation.
        #   person.people.build(:name => "Bozo")
        #
        # @param [ Hash ] attributes The attributes to build the document with.
        # @param [ Class ] type Optional class to build the document with.
        #
        # @return [ Document ] The new document.
        def build(attributes = {}, type = nil)
          Factory.build(type || metadata.klass, attributes).tap do |doc|
            doc.identify
            append(doc)
            yield(doc) if block_given?
          end
        end
        alias :new :build

        # Clear the relation. Will delete the documents from the db if they are
        # already persisted.
        #
        # @example Clear the relation.
        #   person.addresses.clear
        #
        # @return [ Many ] The empty relation.
        def clear
          tap do |proxy|
            atomically(:$unset) { proxy.delete_all }
          end
        end

        # Returns a count of the number of documents in the association that have
        # actually been persisted to the database.
        #
        # Use #size if you want the total number of documents.
        #
        # @example Get the count of persisted documents.
        #   person.addresses.count
        #
        # @return [ Integer ] The total number of persisted embedded docs, as
        #   flagged by the #persisted? method.
        def count
          target.select { |doc| doc.persisted? }.size
        end

        # Create a new document in the relation. This is essentially the same
        # as doing a #build then #save on the new document.
        #
        # @example Create a new document in the relation.
        #   person.movies.create(:name => "Bozo")
        #
        # @param [ Hash ] attributes The attributes to build the document with.
        # @param [ Class ] type Optional class to create the document with.
        #
        # @return [ Document ] The newly created document.
        def create(attributes = {}, type = nil, &block)
          build(attributes, type, &block).tap { |doc| doc.save }
        end

        # Create a new document in the relation. This is essentially the same
        # as doing a #build then #save on the new document. If validation
        # failed on the document an error will get raised.
        #
        # @example Create the document.
        #   person.addresses.create!(:street => "Unter der Linden")</tt>
        #
        # @param [ Hash ] attributes The attributes to build the document with.
        # @param [ Class ] type Optional class to create the document with.
        #
        # @raise [ Errors::Validations ] If a validation error occured.
        #
        # @return [ Document ] The newly created document.
        def create!(attributes = {}, type = nil, &block)
          build(attributes, type, &block).tap { |doc| doc.save! }
        end

        # Delete the supplied document from the target. This method is proxied
        # in order to reindex the array after the operation occurs.
        #
        # @example Delete the document from the relation.
        #   person.addresses.delete(address)
        #
        # @param [ Document ] document The document to be deleted.
        #
        # @return [ Document, nil ] The deleted document or nil if nothing deleted.
        #
        # @since 2.0.0.rc.1
        def delete(document)
          target.delete_one(document).tap do |doc|
            if doc && !binding?
              if assigning?
                base.add_atomic_pull(doc)
              else
                doc.delete(:suppress => true)
              end
              unbind_one(doc)
            end
            reindex
          end
        end

        # Delete all the documents in the association without running callbacks.
        #
        # @example Delete all documents from the relation.
        #   person.addresses.delete_all
        #
        # @example Conditionally delete documents from the relation.
        #   person.addresses.delete_all(:conditions => { :street => "Bond" })
        #
        # @param [ Hash ] conditions Conditions on which documents to delete.
        #
        # @return [ Integer ] The number of documents deleted.
        def delete_all(conditions = {})
          atomically(:$pull) { remove_all(conditions, :delete) }
        end

        # Destroy all the documents in the association whilst running callbacks.
        #
        # @example Destroy all documents from the relation.
        #   person.addresses.destroy_all
        #
        # @example Conditionally destroy documents from the relation.
        #   person.addresses.destroy_all(:conditions => { :street => "Bond" })
        #
        # @param [ Hash ] conditions Conditions on which documents to destroy.
        #
        # @return [ Integer ] The number of documents destroyed.
        def destroy_all(conditions = {})
          atomically(:$pull) { remove_all(conditions, :destroy) }
        end

        # Finds a document in this association through several different
        # methods.
        #
        # @example Find a document by its id.
        #   person.addresses.find(BSON::ObjectId.new)
        #
        # @example Find documents for multiple ids.
        #   person.addresses.find([ BSON::ObjectId.new, BSON::ObjectId.new ])
        #
        # @example Find documents based on conditions.
        #   person.addresses.find(:all, :conditions => { :number => 10 })
        #   person.addresses.find(:first, :conditions => { :number => 10 })
        #   person.addresses.find(:last, :conditions => { :number => 10 })
        #
        # @param [ Array<Object> ] args Various arguments.
        #
        # @return [ Array<Document>, Document ] A single or multiple documents.
        def find(*args)
          criteria.find(*args)
        end

        # Instantiate a new embeds_many relation.
        #
        # @example Create the new relation.
        #   Many.new(person, addresses, metadata)
        #
        # @param [ Document ] base The document this relation hangs off of.
        # @param [ Array<Document> ] target The child documents of the relation.
        # @param [ Metadata ] metadata The relation's metadata
        #
        # @return [ Many ] The proxy.
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            target.each_with_index do |doc, index|
              integrate(doc)
              doc._index = index
            end
          end
        end

        # Get all the documents in the relation that are loaded into memory.
        #
        # @example Get the in memory documents.
        #   relation.in_memory
        #
        # @return [ Array<Document> ] The documents in memory.
        #
        # @since 2.1.0
        def in_memory
          target
        end

        # Substitutes the supplied target documents for the existing documents
        # in the relation.
        #
        # @example Substitute the relation's target.
        #   person.addresses.substitute([ address ])
        #
        # @param [ Array<Document> ] new_target The replacement array.
        # @param [ true, false ] building Are we in build mode?
        #
        # @return [ Many ] The proxied relation.
        #
        # @since 2.0.0.rc.1
        def substitute(replacement)
          tap do |proxy|
            if replacement.blank?
              if assigning?
                base.atomic_unsets.push(proxy.first.atomic_path)
              end
              proxy.clear
            else
              atomically(:$set) do
                if replacement.first.is_a?(Hash)
                  replacement = Many.builder(metadata, replacement).build
                end
                proxy.target = replacement.compact
                if assigning?
                  base.delayed_atomic_sets[metadata.name.to_s] = proxy.as_document
                end
                proxy.target.each_with_index do |doc, index|
                  integrate(doc)
                  doc._index = index
                  doc.save if base.persisted? && !assigning?
                end
              end
            end
          end
        end

        # Get this relation as as its representation in the database.
        #
        # @example Convert the relation to an attributes hash.
        #   person.addresses.as_document
        #
        # @return [ Array<Hash> ] The relation as stored in the db.
        #
        # @since 2.0.0.rc.1
        def as_document
          [].tap do |attributes|
            target.each do |doc|
              attributes << doc.as_document
            end
          end
        end

        # Get a criteria for the embedded documents without the default scoping
        # applied.
        #
        # @example Get the unscoped criteria.
        #   person.addresses.unscoped
        #
        # @return [ Criteria ] The unscoped criteria.
        #
        # @since 2.2.1
        def unscoped
          criteria(false)
        end

        private

        # Appends the document to the target array, updating the index on the
        # document at the same time.
        #
        # @example Append to the document.
        #   relation.append(document)
        #
        # @param [ Document ] document The document to append to the target.
        #
        # @since 2.0.0.rc.1
        def append(document)
          target.push(document)
          integrate(document)
          document._index = target.size - 1
        end

        # Instantiate the binding associated with this relation.
        #
        # @example Create the binding.
        #   relation.binding([ address ])
        #
        # @param [ Array<Document> ] new_target The new documents to bind with.
        #
        # @return [ Binding ] The many binding.
        #
        # @since 2.0.0.rc.1
        def binding
          Bindings::Embedded::Many.new(base, target, metadata)
        end

        # Returns the criteria object for the target class with its documents set
        # to target.
        #
        # @example Get a criteria for the relation.
        #   relation.criteria
        #
        # @return [ Criteria ] A new criteria.
        def criteria(scoped = true)
          klass.criteria(true, scoped).tap do |criterion|
            criterion.documents = target
          end
        end

        # Integrate the document into the relation. will set its metadata and
        # attempt to bind the inverse.
        #
        # @example Integrate the document.
        #   relation.integrate(document)
        #
        # @param [ Document ] document The document to integrate.
        #
        # @since 2.1.0
        def integrate(document)
          characterize_one(document)
          bind_one(document)
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
        def method_missing(name, *args, &block)
          return super if target.respond_to?(name)
          klass.send(:with_scope, criteria) do
            criteria.send(name, *args, &block)
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
          base.persisted? && !binding?
        end

        # Reindex all the target elements. This is useful when performing
        # operations on the proxied target directly and the indices need to
        # match that on the database side.
        #
        # @example Reindex the relation.
        #   person.addresses.reindex
        #
        # @since 2.0.0.rc.1
        def reindex
          target.each_with_index do |doc, index|
            doc._index = index
          end
        end

        # Remove all documents from the relation, either with a delete or a
        # destroy depending on what this was called through.
        #
        # @example Destroy documents from the relation.
        #   relation.remove_all(:conditions => { :num => 1 }, true)
        #
        # @param [ Hash ] conditions Conditions to filter by.
        # @param [ true, false ] destroy If true then destroy, else delete.
        #
        # @return [ Integer ] The number of documents removed.
        def remove_all(conditions = {}, method = :delete)
          criteria = find(:all, conditions || {})
          criteria.size.tap do
            criteria.each do |doc|
              target.delete_one(doc)
              doc.send(method, :suppress => true) unless assigning?
              unbind_one(doc)
            end
            reindex
          end
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Embedded::Many.builder(meta, object)
          #
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build
          #   with.
          #
          # @return [ Builder ] A newly instantiated builder object.
          #
          # @since 2.0.0.rc.1
          def builder(meta, object, loading = false)
            Builders::Embedded::Many.new(meta, object, loading)
          end

          # Returns true if the relation is an embedded one. In this case
          # always true.
          #
          # @example Is the relation embedded?
          #   Embedded::Many.embedded?
          #
          # @return [ true ] true.
          #
          # @since 2.0.0.rc.1
          def embedded?
            true
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # @example Get the relation macro.
          #   Mongoid::Relations::Embedded::Many.macro
          #
          # @return [ Symbol ] :embeds_many
          #
          # @since 2.0.0.rc.1
          def macro
            :embeds_many
          end

          # Return the nested builder that is responsible for generating the
          # documents that will be used by this relation.
          #
          # @example Get the nested builder.
          #   NestedAttributes::Many.builder(attributes, options)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Hash ] attributes The attributes to build with.
          # @param [ Hash ] options The builder options.
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
          # @return [ NestedBuilder ] The nested attributes builder.
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
          # @return [ Mongoid::Atomic::Paths::Embedded::Many ]
          #   The embedded many atomic path calculator.
          #
          # @since 2.1.0
          def path(document)
            Mongoid::Atomic::Paths::Embedded::Many.new(document)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # @example Does this relation store a foreign key?
          #   Embedded::Many.stores_foreign_key?
          #
          # @return [ false ] false.
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
            [ :as, :cyclic, :order, :versioned ]
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
