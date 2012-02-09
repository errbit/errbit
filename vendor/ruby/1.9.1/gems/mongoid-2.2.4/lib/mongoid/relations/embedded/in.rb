# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded

      # This class defines the behaviour necessary to handle relations that are
      # embedded within another relation, either as a single document or
      # multiple documents.
      class In < Relations::One

        # Instantiate a new embedded_in relation.
        #
        # @example Create the new relation.
        #   Embedded::In.new(name, person, metadata)
        #
        # @param [ Document ] base The document the relation hangs off of.
        # @param [ Document ] target The target (parent) of the relation.
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @return [ In ] The proxy.
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            characterize_one(target)
            bind_one
            base.save if persistable?
          end
        end

        # Substitutes the supplied target documents for the existing document
        # in the relation.
        #
        # @example Substitute the new document.
        #   person.name.substitute(new_name)
        #
        # @param [ Document ] other A document to replace the target.
        #
        # @return [ Document, nil ] The relation or nil.
        #
        # @since 2.0.0.rc.1
        def substitute(replacement)
          tap do |proxy|
            proxy.unbind_one
            unless replacement
              base.delete if persistable?
              return nil
            end
            base.new_record = true
            proxy.target = replacement
            proxy.bind_one
          end
        end

        private

        # Instantiate the binding associated with this relation.
        #
        # @example Get the binding.
        #   binding([ address ])
        #
        # @param [ Proxy ] new_target The new documents to bind with.
        #
        # @return [ Binding ] A binding object.
        #
        # @since 2.0.0.rc.1
        def binding
          Bindings::Embedded::In.new(base, target, metadata)
        end

        # Characterize the document.
        #
        # @example Set the base metadata.
        #   relation.characterize_one(document)
        #
        # @param [ Document ] document The document to set the metadata on.
        #
        # @since 2.1.0
        def characterize_one(document)
          unless base.metadata
            base.metadata = metadata.inverse_metadata(document)
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
          target.persisted? && !binding? && !building?
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Embedded::In.builder(meta, object, person)
          #
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build with.
          #
          # @return [ Builder ] A newly instantiated builder object.
          #
          # @since 2.0.0.rc.1
          def builder(meta, object, loading = false)
            Builders::Embedded::In.new(meta, object, loading)
          end

          # Returns true if the relation is an embedded one. In this case
          # always true.
          #
          # @example Is this relation embedded?
          #   Embedded::In.embedded?
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
          # @example Get the macro.
          #   Mongoid::Relations::Embedded::In.macro
          #
          # @return [ Symbol ] :embedded_in.
          #
          # @since 2.0.0.rc.1
          def macro
            :embedded_in
          end

          # Return the nested builder that is responsible for generating
          # the documents that will be used by this relation.
          #
          # @example Get the builder.
          #   NestedAttributes::One.builder(attributes, options)
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
          # @return [ Builder ] A newly instantiated nested builder object.
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
          #   Embedded::In.stores_foreign_key?
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
            [ :cyclic, :polymorphic ]
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
