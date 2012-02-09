# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Referenced #:nodoc:

      # This class defines the behaviour for all relations that are a
      # many-to-many between documents in different collections.
      class ManyToMany < Many

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
            [].tap do |ids|
              args.flatten.each do |doc|
                next unless doc
                append(doc)
                if persistable? || creating?
                  ids.push(doc.id)
                  doc.save
                else
                  base.send(metadata.foreign_key).push(doc.id)
                  base.synced[metadata.foreign_key] = false
                end
              end
              if persistable? || creating?
                base.push_all(metadata.foreign_key, ids)
                base.synced[metadata.foreign_key] = false
              end
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
            base.send(metadata.foreign_key).push(doc.id)
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
          super.tap do |doc|
            base.send(metadata.foreign_key).delete_one(doc.id)
            base.push(metadata.foreign_key, doc.id)
            base.synced[metadata.foreign_key] = false
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
          super.tap do |doc|
            base.send(metadata.foreign_key).delete_one(doc.id)
            base.push(metadata.foreign_key, doc.id)
            base.synced[metadata.foreign_key] = false
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
          super.tap do |doc|
            if doc && persistable?
              base.pull(metadata.foreign_key, doc.id)
              base.synced[metadata.foreign_key] = false
            end
          end
        end

        # Removes all associations between the base document and the target
        # documents by deleting the foreign keys and the references, orphaning
        # the target documents in the process.
        #
        # @example Nullify the relation.
        #   person.preferences.nullify
        #
        # @since 2.0.0.rc.1
        def nullify
          unless metadata.forced_nil_inverse?
            criteria.pull(metadata.inverse_foreign_key, base.id)
          end
          if persistable?
            base.set(
              metadata.foreign_key,
              base.send(metadata.foreign_key).clear
            )
          end
          target.clear do |doc|
            unbind_one(doc)
          end
        end
        alias :nullify_all :nullify
        alias :clear :nullify
        alias :purge :nullify

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
        # @return [ Binding ] The binding.
        #
        # @since 2.0.0.rc.1
        def binding
          Bindings::Referenced::ManyToMany.new(base, target, metadata)
        end

        # Returns the criteria object for the target class with its documents set
        # to target.
        #
        # @example Get a criteria for the relation.
        #   relation.criteria
        #
        # @return [ Criteria ] A new criteria.
        def criteria
          ManyToMany.criteria(metadata, base.send(metadata.foreign_key))
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Referenced::ManyToMany.builder(meta, object)
          #
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build
          #   with.
          #
          # @return [ Builder ] A new builder object.
          #
          # @since 2.0.0.rc.1
          def builder(meta, object, loading = false)
            Builders::Referenced::ManyToMany.new(meta, object, loading)
          end

          # Create the standard criteria for this relation given the supplied
          # metadata and object.
          #
          # @example Get the criteria.
          #   Proxy.criteria(meta, object)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Object ] object The object for the criteria.
          # @param [ Class ] type The criteria class.
          #
          # @return [ Criteria ] The criteria.
          #
          # @since 2.1.0
          def criteria(metadata, object, type = nil)
            metadata.klass.any_in(:_id => object)
          end

          # Get the criteria that is used to eager load a relation of this
          # type.
          #
          # @example Get the eager load criteria.
          #   Proxy.eager_load(metadata, criteria)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Criteria ] criteria The criteria being used.
          #
          # @return [ Criteria ] The criteria to eager load the relation.
          #
          # @since 2.2.0
          def eager_load(metadata, criteria)
            raise Errors::EagerLoad.new(metadata.name)
          end

          # Returns true if the relation is an embedded one. In this case
          # always false.
          #
          # @example Is this relation embedded?
          #   Referenced::ManyToMany.embedded?
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
          #   Referenced::ManyToMany.foreign_key_default
          #
          # @return [ Array ] Always an empty array.
          #
          # @since 2.0.0.rc.1
          def foreign_key_default
            []
          end

          # Returns the suffix of the foreign key field, either "_id" or "_ids".
          #
          # @example Get the suffix for the foreign key.
          #   Referenced::ManyToMany.foreign_key_suffix
          #
          # @return [ String ] "_ids"
          #
          # @since 2.0.0.rc.1
          def foreign_key_suffix
            "_ids"
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # @example Get the macro.
          #   Referenced::ManyToMany.macro
          #
          # @return [ Symbol ] :references_and_referenced_in_many
          def macro
            :references_and_referenced_in_many
          end

          # Return the nested builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the nested builder.
          #   Referenced::ManyToMany.builder(attributes, options)
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
          # @return [ true ] Always true.
          #
          # @since 2.0.0.rc.1
          def stores_foreign_key?
            true
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
            [ :autosave, :dependent, :foreign_key, :index, :order ]
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
