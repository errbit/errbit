# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This module contains the core macros for defining relations between
    # documents. They can be either embedded or referenced (relational).
    module Macros
      extend ActiveSupport::Concern

      included do
        cattr_accessor :embedded
        class_attribute :relations
        self.embedded = false
        self.relations = {}

        # For backwards compatibility, alias the class method for associations
        # and embedding as well. Fix in related gems.
        #
        # @todo Affected libraries: Machinist
        class << self
          alias :associations :relations
          alias :embedded? :embedded
        end
      end

      # Get the metadata for all the defined relations.
      #
      # @note Refactored from using delegate for class load performance.
      #
      # @example Get the relations.
      #   model.relations
      #
      # @return [ Hash<String, Metadata> ] The relation metadata.
      def relations
        self.class.relations
      end
      alias :associations :relations

      module ClassMethods #:nodoc:

        # Adds the relation back to the parent document. This macro is
        # necessary to set the references from the child back to the parent
        # document. If a child does not define this relation calling
        # persistence methods on the child object will cause a save to fail.
        #
        # @example Define the relation.
        #
        #   class Person
        #     include Mongoid::Document
        #     embeds_many :addresses
        #   end
        #
        #   class Address
        #     include Mongoid::Document
        #     embedded_in :person
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def embedded_in(name, options = {}, &block)
          characterize(name, Embedded::In, options, &block).tap do |meta|
            self.embedded = true
            relate(name, meta)
          end
        end

        # Adds the relation from a parent document to its children. The name
        # of the relation needs to be a pluralized form of the child class
        # name.
        #
        # @example Define the relation.
        #
        #   class Person
        #     include Mongoid::Document
        #     embeds_many :addresses
        #   end
        #
        #   class Address
        #     include Mongoid::Document
        #     embedded_in :person
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def embeds_many(name, options = {}, &block)
          characterize(name, Embedded::Many, options, &block).tap do |meta|
            relate(name, meta)
            validates_relation(meta)
          end
        end

        # Adds the relation from a parent document to its child. The name
        # of the relation needs to be a singular form of the child class
        # name.
        #
        # @example Define the relation.
        #
        #   class Person
        #     include Mongoid::Document
        #     embeds_one :name
        #   end
        #
        #   class Name
        #     include Mongoid::Document
        #     embedded_in :person
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def embeds_one(name, options = {}, &block)
          characterize(name, Embedded::One, options, &block).tap do |meta|
            relate(name, meta)
            builder(name, meta).creator(name)
            validates_relation(meta)
          end
        end

        # Adds a relational association from the child Document to a Document in
        # another database or collection.
        #
        # @example Define the relation.
        #
        #   class Game
        #     include Mongoid::Document
        #     belongs_to :person
        #   end
        #
        #   class Person
        #     include Mongoid::Document
        #     has_one :game
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def belongs_to(name, options = {}, &block)
          characterize(name, Referenced::In, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
            autosave(meta)
            validates_relation(meta)
          end
        end
        alias :belongs_to_related :belongs_to
        alias :referenced_in :belongs_to

        # Adds a relational association from a parent Document to many
        # Documents in another database or collection.
        #
        # @example Define the relation.
        #
        #   class Person
        #     include Mongoid::Document
        #     has_many :posts
        #   end
        #
        #   class Game
        #     include Mongoid::Document
        #     belongs_to :person
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def has_many(name, options = {}, &block)
          characterize(name, Referenced::Many, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
            autosave(meta)
            validates_relation(meta)
          end
        end
        alias :has_many_related :has_many
        alias :references_many :has_many

        # Adds a relational many-to-many association between many of this
        # Document and many of another Document.
        #
        # @example Define the relation.
        #
        #   class Person
        #     include Mongoid::Document
        #     has_and_belongs_to_many :preferences
        #   end
        #
        #   class Preference
        #     include Mongoid::Document
        #     has_and_belongs_to_many :people
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        #
        # @since 2.0.0.rc.1
        def has_and_belongs_to_many(name, options = {}, &block)
          characterize(name, Referenced::ManyToMany, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta, Array)
            autosave(meta)
            validates_relation(meta)
            synced(meta)
          end
        end
        alias :references_and_referenced_in_many :has_and_belongs_to_many

        # Adds a relational association from the child Document to a Document in
        # another database or collection.
        #
        # @example Define the relation.
        #
        #   class Game
        #     include Mongoid::Document
        #     belongs_to :person
        #   end
        #
        #   class Person
        #     include Mongoid::Document
        #     has_one :game
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def has_one(name, options = {}, &block)
          characterize(name, Referenced::One, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
            builder(name, meta).creator(name).autosave(meta)
            validates_relation(meta)
          end
        end
        alias :has_one_related :has_one
        alias :references_one :has_one

        private

        # Create the metadata for the relation.
        #
        # @example Create the metadata.
        #   Person.characterize(:posts, Referenced::Many, {})
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Object ] relation The type of relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        #
        # @return [ Metadata ] The metadata for the relation.
        def characterize(name, relation, options, &block)
          Metadata.new({
            :relation => relation,
            :extend => create_extension_module(name, &block),
            :inverse_class_name => self.name,
            :name => name
          }.merge(options))
        end

        # Generate a named extension module suitable for marshaling
        #
        # @example Get the module.
        #   Person.create_extension_module(:posts, &block)
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Proc ] block Optional block for defining extensions.
        #
        # @return [ Module, nil ] The extension or nil.
        #
        # @since 2.1.0
        def create_extension_module(name, &block)
          if block
            extension_module_name =
              "#{self.to_s.demodulize}#{name.to_s.camelize}RelationExtension"
            silence_warnings do
              self.const_set(extension_module_name, Module.new(&block))
            end
            "#{self}::#{extension_module_name}".constantize
          end
        end

        # Defines a field to be used as a foreign key in the relation and
        # indexes it if defined.
        #
        # @example Set up the relational fields and indexes.
        #   Person.reference(metadata)
        #
        # @param [ Metadata ] metadata The metadata for the relation.
        def reference(metadata, type = Object)
          polymorph(metadata).cascade(metadata)
          if metadata.relation.stores_foreign_key?
            key = metadata.foreign_key
            field(
              key,
              :type => type,
              :identity => true,
              :metadata => metadata,
              :default => metadata.foreign_key_default
            )
            index(key, :background => true) if metadata.indexed?
          end
        end

        # Creates a relation for the given name, metadata and relation. It adds
        # the metadata to the relations hash and has the accessors set up.
        #
        # @example Set up the relation and accessors.
        #   Person.relate(:addresses, Metadata)
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Metadata ] metadata The metadata for the relation.
        def relate(name, metadata)
          self.relations = relations.merge(name.to_s => metadata)
          getter(name, metadata).setter(name, metadata)
        end
      end
    end
  end
end
