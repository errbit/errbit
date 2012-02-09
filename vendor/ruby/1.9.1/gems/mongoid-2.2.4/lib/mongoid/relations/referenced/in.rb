# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Referenced #:nodoc:

      # This class handles all behaviour for relations that are either
      # one-to-many or one-to-one, where the foreign key is store on this side
      # of the relation and the reference is to document(s) in another
      # collection.
      class In < Relations::One

        # Instantiate a new referenced_in relation.
        #
        # @example Create the new relation.
        #   Referenced::In.new(game, person, metadata)
        #
        # @param [ Document ] base The document this relation hangs off of.
        # @param [ Document, Array<Document> ] target The target (parent) of the
        #   relation.
        # @param [ Metadata ] metadata The relation's metadata.
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            characterize_one(target)
            bind_one
          end
        end

        # Substitutes the supplied target documents for the existing document
        # in the relation.
        #
        # @example Substitute the relation.
        #   name.substitute(new_name)
        #
        # @param [ Document, Array<Document> ] new_target The replacement.
        # @param [ true, false ] building Are we in build mode?
        #
        # @return [ In, nil ] The relation or nil.
        #
        # @since 2.0.0.rc.1
        def substitute(replacement)
          tap do |proxy|
            proxy.unbind_one
            return nil unless replacement
            proxy.target = replacement
            proxy.bind_one
          end
        end

        private

        # Instantiate the binding associated with this relation.
        #
        # @example Get the binding object.
        #   binding([ address ])
        #
        # @param [ Document, Array<Document> ] new_target The replacement.
        #
        # @return [ Binding ] The binding object.
        #
        # @since 2.0.0.rc.1
        def binding
          Bindings::Referenced::In.new(base, target, metadata)
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
          target.persisted? && !binding? && !building?
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Referenced::In.builder(meta, object)
          #
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build
          #   with.
          #
          # @return [ Builder ] A new builder object.
          #
          # @since 2.0.0.rc.1
          def builder(meta, object, loading = false)
            Builders::Referenced::In.new(meta, object, loading)
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
            type.where(:_id => object)
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
            raise Errors::EagerLoad.new(metadata.name) if metadata.polymorphic?
            klass, foreign_key = metadata.klass, metadata.foreign_key
            klass.any_in("_id" => criteria.load_ids(foreign_key).uniq).each do |doc|
              IdentityMap.set(doc)
            end
          end

          # Returns true if the relation is an embedded one. In this case
          # always false.
          #
          # @example Is this relation embedded?
          #   Referenced::In.embedded?
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
          #   Referenced::In.foreign_key_default
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
          #   Referenced::In.foreign_key_suffix
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
          #   Referenced::In.macro
          #
          # @return [ Symbol ] :referenced_in
          def macro
            :referenced_in
          end

          # Return the nested builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the nested builder.
          #   Referenced::In.builder(attributes, options)
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
            Builders::NestedAttributes::One.new(metadata, attributes, options)
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
          #   Referenced::In.stores_foreign_key?
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
            [ :autosave, :foreign_key, :index, :polymorphic ]
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
            false
          end
        end
      end
    end
  end
end
