# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:

      # This class defines the behaviour needed for embedded one to one
      # relations.
      class One < Relations::One

        # Instantiate a new embeds_one relation.
        #
        # @example Create the new proxy.
        #   One.new(person, name, metadata)
        #
        # @param [ Document ] base The document this relation hangs off of.
        # @param [ Document ] target The child document in the relation.
        # @param [ Metadata ] metadata The relation's metadata
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            characterize_one(target)
            bind_one
            target.save if persistable?
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
            if assigning?
              base.atomic_unsets.push(proxy.atomic_path)
            else
              proxy.delete if persistable?
            end
            proxy.unbind_one
            return nil unless replacement
            proxy.target = replacement
            proxy.bind_one
          end
        end

        private

        # Instantiate the binding associated with this relation.
        #
        # @example Get the binding.
        #   relation.binding([ address ])
        #
        # @param [ Document ] new_target The new document to bind with.
        #
        # @return [ Binding ] The relation's binding.
        #
        # @since 2.0.0.rc.1
        def binding
          Bindings::Embedded::One.new(base, target, metadata)
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
          base.persisted? && !binding? && !building? && !assigning?
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Embedded::One.builder(meta, object, person)
          #
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build with.
          #
          # @return [ Builder ] A newly instantiated builder object.
          #
          # @since 2.0.0.rc.1
          def builder(meta, object, loading = false)
            Builders::Embedded::One.new(meta, object, loading)
          end

          # Returns true if the relation is an embedded one. In this case
          # always true.
          #
          # @example Is this relation embedded?
          #   Embedded::One.embedded?
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
          #   Mongoid::Relations::Embedded::One.macro
          #
          # @return [ Symbol ] :embeds_one.
          #
          # @since 2.0.0.rc.1
          def macro
            :embeds_one
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
          # @return [ Mongoid::Atomic::Paths::Embedded::One ]
          #   The embedded one atomic path calculator.
          #
          # @since 2.1.0
          def path(document)
            Mongoid::Atomic::Paths::Embedded::One.new(document)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # @example Does this relation store a foreign key?
          #   Embedded::One.stores_foreign_key?
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
            [ :as, :cyclic ]
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
