# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # The "Grand Poobah" of information about any relation is this class. It
    # contains everything you could ever possible want to know.
    class Metadata < Hash

      delegate :foreign_key_default, :stores_foreign_key?, :to => :relation

      # Returns the as option of the relation.
      #
      # @example Get the as option.
      #   metadata.as
      #
      # @return [ true, false ] The as option.
      #
      # @since 2.1.0
      def as
        self[:as]
      end

      # Tells whether an as option exists.
      #
      # @example Is the as option set?
      #   metadata.as?
      #
      # @return [ true, false ] True if an as exists, false if not.
      #
      # @since 2.0.0.rc.1
      def as?
        !!as
      end

      # Returns the autosave option of the relation.
      #
      # @example Get the autosave option.
      #   metadata.autosave
      #
      # @return [ true, false ] The autosave option.
      #
      # @since 2.1.0
      def autosave
        self[:autosave]
      end

      # Does the metadata have a autosave option?
      #
      # @example Is the relation autosaving?
      #   metadata.autosave?
      #
      # @return [ true, false ] If the relation autosaves.
      #
      # @since 2.1.0
      def autosave?
        !!autosave
      end

      # Gets a relation builder associated with the relation this metadata is
      # for.
      #
      # @example Get the builder.
      #   metadata.builder(document)
      #
      # @param [ Object ] object A document or attributes to give the builder.
      #
      # @return [ Builder ] The builder for the relation.
      #
      # @since 2.0.0.rc.1
      def builder(object, loading = false)
        relation.builder(self, object, loading)
      end

      # Returns the name of the strategy used for handling dependent relations.
      #
      # @example Get the strategy.
      #   metadata.cascade_strategy
      #
      # @return [ Object ] The cascading strategy to use.
      #
      # @since 2.0.0.rc.1
      def cascade_strategy
        if dependent?
          strategy =
            %{Mongoid::Relations::Cascading::#{dependent.to_s.classify}}
          strategy.constantize
        else
          return nil
        end
      end

      # Returns the name of the class that this relation contains. If the
      # class_name was provided as an option this will return that, otherwise
      # it will determine the name from the name property.
      #
      # @example Get the class name.
      #   metadata.class_name
      #
      # @return [ String ] The name of the relation's proxied class.
      #
      # @since 2.0.0.rc.1
      def class_name
        @class_name ||= (self[:class_name] || classify)
      end

      # Get the foreign key contraint for the metadata.
      #
      # @example Get the constaint.
      #   metadata.constraint
      #
      # @return [ Constraint ] The constraint.
      #
      # @since 2.0.0.rc.1
      def constraint
        @constraint ||= Constraint.new(self)
      end

      # Get the criteria that is used to query for this metadata's relation.
      #
      # @example Get the criteria.
      #   metadata.criteria([ id_one, id_two ])
      #
      # @param [ Object ] object The foreign key used for the query.
      #
      # @return [ Criteria ] The criteria.
      #
      # @since 2.1.0
      def criteria(object, type = nil)
        query = relation.criteria(self, object, type)
        order ? query.order_by(order) : query
      end

      # Returns the cyclic option of the relation.
      #
      # @example Get the cyclic option.
      #   metadata.cyclic
      #
      # @return [ true, false ] The cyclic option.
      #
      # @since 2.1.0
      def cyclic
        self[:cyclic]
      end

      # Does the metadata have a cyclic option?
      #
      # @example Is the metadata cyclic?
      #   metadata.cyclic?
      #
      # @return [ true, false ] If the metadata is cyclic.
      #
      # @since 2.1.0
      def cyclic?
        !!cyclic
      end

      # Returns the dependent option of the relation.
      #
      # @example Get the dependent option.
      #   metadata.dependent
      #
      # @return [ Symbol ] The dependent option.
      #
      # @since 2.1.0
      def dependent
        self[:dependent]
      end

      # Does the metadata have a dependent option?
      #
      # @example Is the metadata performing cascades?
      #   metadata.dependent?
      #
      # @return [ true, false ] If the metadata cascades.
      #
      # @since 2.1.0
      def dependent?
        !!dependent
      end

      # Get the criteria needed to eager load this relation.
      #
      # @example Get the eager loading criteria.
      #   metadata.eager_load(criteria)
      #
      # @param [ Criteria ] criteria The criteria to load from.
      #
      # @return [ Criteria ] The eager loading criteria.
      #
      # @since 2.2.0
      def eager_load(criteria)
        relation.eager_load(self, criteria.clone)
      end

      # Will determine if the relation is an embedded one or not. Currently
      # only checks against embeds one and many.
      #
      # @example Is the document embedded.
      #   metadata.embedded?
      #
      # @return [ true, false ] True if embedded, false if not.
      #
      # @since 2.0.0.rc.1
      def embedded?
        @embedded ||= (macro == :embeds_one || macro == :embeds_many)
      end

      # Returns the extension of the relation.
      #
      # @example Get the relation extension.
      #   metadata.extension
      #
      # @return [ Module ] The extension or nil.
      #
      # @since 2.0.0.rc.1
      def extension
        self[:extend]
      end

      # Tells whether an extension definition exist for this relation.
      #
      # @example Is an extension defined?
      #   metadata.extension?
      #
      # @return [ true, false ] True if an extension exists, false if not.
      #
      # @since 2.0.0.rc.1
      def extension?
        !!extension
      end

      # Does this metadata have a forced nil inverse_of defined. (Used in many
      # to manies)
      #
      # @example Is this a forced nil inverse?
      #   metadata.forced_nil_inverse?
      #
      # @return [ true, false ] If inverse_of has been explicitly set to nil.
      #
      # @since 2.3.3
      def forced_nil_inverse?
        has_key?(:inverse_of) && inverse_of.nil?
      end

      # Handles all the logic for figuring out what the foreign_key is for each
      # relations query. The logic is as follows:
      #
      # 1. If the developer defined a custom key, use that.
      # 2. If the relation stores a foreign key,
      #    use the class_name_id strategy.
      # 3. If the relation does not store the key,
      #    use the inverse_class_name_id strategy.
      #
      # @example Get the foreign key.
      #   metadata.foreign_key
      #
      # @return [ String ] The foreign key for the relation.
      #
      # @since 2.0.0.rc.1
      def foreign_key
        @foreign_key ||= determine_foreign_key
      end

      # Get the name of the method to check if the foreign key has changed.
      #
      # @example Get the foreign key check method.
      #   metadata.foreign_key_check
      #
      # @return [ String ] The foreign key check.
      #
      # @since 2.1.0
      def foreign_key_check
        @foreign_key_check ||= "#{foreign_key}_changed?"
      end

      # Returns the name of the method used to set the foreign key on a
      # document.
      #
      # @example Get the setter for the foreign key.
      #   metadata.foreign_key_setter
      #
      # @return [ String ] The foreign_key plus =.
      #
      # @since 2.0.0.rc.1
      def foreign_key_setter
        @foreign_key_setter ||= "#{foreign_key}="
      end

      # Returns the index option of the relation.
      #
      # @example Get the index option.
      #   metadata.index
      #
      # @return [ true, false ] The index option.
      #
      # @since 2.1.0
      def index
        self[:index]
      end

      # Tells whether a foreign key index exists on the relation.
      #
      # @example Is the key indexed?
      #   metadata.indexed?
      #
      # @return [ true, false ] True if an index exists, false if not.
      #
      # @since 2.0.0.rc.1
      def indexed?
        !!index
      end

      # Instantiate new metadata for a relation.
      #
      # @example Create the new metadata.
      #   Metadata.new(:name => :addresses)
      #
      # @param [ Hash ] properties The relation options.
      #
      # @since 2.0.0.rc.1
      def initialize(properties = {})
        Options.validate!(properties)
        merge!(properties)
      end

      # Since a lot of the information from the metadata is inferred and not
      # explicitly stored in the hash, the inspection needs to be much more
      # detailed.
      #
      # @example Inspect the metadata.
      #   metadata.inspect
      #
      # @return [ String ] Oodles of information in a nice format.
      #
      # @since 2.0.0.rc.1
      def inspect
        "#<Mongoid::Relations::Metadata\n" <<
        "  class_name:           #{class_name},\n" <<
        "  cyclic:               #{cyclic || "No"},\n" <<
        "  dependent:            #{dependent || "None"},\n" <<
        "  inverse_of:           #{inverse_of || "N/A"},\n" <<
        "  key:                  #{key},\n" <<
        "  macro:                #{macro},\n" <<
        "  name:                 #{name},\n" <<
        "  order:                #{order.inspect || "No"},\n" <<
        "  polymorphic:          #{polymorphic? || "No"},\n" <<
        "  relation:             #{relation},\n" <<
        "  setter:               #{setter},\n" <<
        "  versioned:            #{versioned? || "No"}>\n"
      end

      # Get the name of the inverse relation if it exists. If this is a
      # polymorphic relation then just return the :as option that was defined.
      #
      # @example Get the name of the inverse.
      #   metadata.inverse
      #
      # @param [ Document ] other The document to aid in the discovery.
      #
      # @return [ Symbol ] The inverse name.
      #
      # @since 2.0.0.rc.1
      def inverse(other = nil)
        return self[:inverse_of] if has_key?(:inverse_of)
        return self[:as] || lookup_inverse(other) if polymorphic?
        @inverse ||= (cyclic? ? cyclic_inverse : inverse_relation)
      end

      # Returns the inverse_class_name option of the relation.
      #
      # @example Get the inverse_class_name option.
      #   metadata.inverse_class_name
      #
      # @return [ true, false ] The inverse_class_name option.
      #
      # @since 2.1.0
      def inverse_class_name
        self[:inverse_class_name]
      end

      # Returns the if the inverse class name option exists.
      #
      # @example Is an inverse class name defined?
      #   metadata.inverse_class_name?
      #
      # @return [ true, false ] If the inverse if defined.
      #
      # @since 2.1.0
      def inverse_class_name?
        !!inverse_class_name
      end

      # Used for relational many to many only. This determines the name of the
      # foreign key field on the inverse side of the relation, since in this
      # case there are keys on both sides.
      #
      # @example Find the inverse foreign key
      #   metadata.inverse_foreign_key
      #
      # @return [ String ] The foreign key on the inverse.
      #
      # @since 2.0.0.rc.1
      def inverse_foreign_key
        @inverse_foreign_key ||=
          ( inverse_of ? inverse_of.to_s.singularize : inverse_class_name.demodulize.underscore ) <<
          relation.foreign_key_suffix
      end

      # Returns the inverse class of the proxied relation.
      #
      # @example Get the inverse class.
      #   metadata.inverse_klass
      #
      # @return [ Class ] The class of the inverse of the relation.
      #
      # @since 2.0.0.rc.1
      def inverse_klass
        @inverse_klass ||= inverse_class_name.constantize
      end

      # Get the metadata for the inverse relation.
      #
      # @example Get the inverse metadata.
      #   metadata.inverse_metadata(doc)
      #
      # @param [ Document ] document The document to check.
      #
      # @return [ Metadata ] The inverse metadata.
      #
      # @since 2.1.0
      def inverse_metadata(document)
        document.reflect_on_association(inverse(document))
      end

      # Returns the inverse_of option of the relation.
      #
      # @example Get the inverse_of option.
      #   metadata.inverse_of
      #
      # @return [ true, false ] The inverse_of option.
      #
      # @since 2.1.0
      def inverse_of
        self[:inverse_of]
      end

      # Does the metadata have a inverse_of option?
      #
      # @example Is an inverse_of defined?
      #   metadata.inverse_of?
      #
      # @return [ true, false ] If the relation has an inverse_of defined.
      #
      # @since 2.1.0
      def inverse_of?
        !!inverse_of
      end

      # Returns the setter for the inverse side of the relation.
      #
      # @example Get the inverse setter.
      #   metadata.inverse_setter
      #
      # @param [ Document ] other A document to aid in the discovery.
      #
      # @return [ String ] The inverse setter name.
      #
      # @since 2.0.0.rc.1
      def inverse_setter(other = nil)
        "#{inverse(other)}="
      end

      # Returns the name of the field in which to store the name of the class
      # for the polymorphic relation.
      #
      # @example Get the name of the field.
      #   metadata.inverse_type
      #
      # @return [ String ] The name of the field for storing the type.
      #
      # @since 2.0.0.rc.1
      def inverse_type
        @inverse_type ||=
          relation.stores_foreign_key? && polymorphic? ? "#{name}_type" : nil
      end

      # Gets the setter for the field that sets the type of document on a
      # polymorphic relation.
      #
      # @example Get the inverse type setter.
      #   metadata.inverse_type_setter
      #
      # @return [ String ] The name of the setter.
      #
      # @since 2.0.0.rc.1
      def inverse_type_setter
        @inverse_type_setter ||= inverse_type ? "#{inverse_type}=" : nil
      end

      # This returns the key that is to be used to grab the attributes for the
      # relation or the foreign key or id that a referenced relation will use
      # to query for the object.
      #
      # @example Get the lookup key.
      #   metadata.key
      #
      # @return [ String ] The association name, foreign key name, or _id.
      #
      # @since 2.0.0.rc.1
      def key
        @key ||= determine_key
      end

      # Returns the class of the proxied relation.
      #
      # @example Get the class.
      #   metadata.klass
      #
      # @return [ Class ] The class of the relation.
      #
      # @since 2.0.0.rc.1
      def klass
        @klass ||= class_name.constantize
      end

      # Is this metadata representing a one to many or many to many relation?
      #
      # @example Is the relation a many?
      #   metadata.many?
      #
      # @return [ true, false ] If the relation is a many.
      #
      # @since 2.1.6
      def many?
        @many ||= (relation.macro.to_s =~ /many/)
      end

      # Returns the macro for the relation of this metadata.
      #
      # @example Get the macro.
      #   metadata.macro
      #
      # @return [ Symbol ] The macro.
      #
      # @since 2.0.0.rc.1
      def macro
        relation.macro
      end

      # Get the name associated with this metadata.
      #
      # @example Get the name.
      #   metadata.name
      #
      # @return [ Symbol ] The name.
      #
      # @since 2.1.0
      def name
        self[:name]
      end

      # Is the name defined?
      #
      # @example Is the name defined?
      #   metadata.name?
      #
      # @return [ true, false ] If the name is defined.
      #
      # @since 2.1.0
      def name?
        !!name
      end

      # Does the relation have a destructive dependent option specified. This
      # is true for :dependent => :delete and :dependent => :destroy.
      #
      # @example Is the relation destructive?
      #   metadata.destructive?
      #
      # @return [ true, false ] If the relation is destructive.
      #
      # @since 2.1.0
      def destructive?
        @destructive ||= (dependent == :delete || dependent == :destroy)
      end

      # Gets a relation nested builder associated with the relation this metadata
      # is for. Nested builders are used in conjunction with nested attributes.
      #
      # @example Get the nested builder.
      #   metadata.nested_builder(attributes, options)
      #
      # @param [ Hash ] attributes The attributes to build the relation with.
      # @param [ Hash ] options Options for the nested builder.
      #
      # @return [ NestedBuilder ] The nested builder for the relation.
      #
      # @since 2.0.0.rc.1
      def nested_builder(attributes, options)
        relation.nested_builder(self, attributes, options)
      end

      # Get the path calculator for the supplied document.
      #
      # @example Get the path calculator.
      #   metadata.path(document)
      #
      # @param [ Document ] document The document to calculate on.
      #
      # @return [ Object ] The atomic path calculator.
      #
      # @since 2.1.0
      def path(document)
        relation.path(document)
      end

      # Returns true if the relation is polymorphic.
      #
      # @example Is the relation polymorphic?
      #   metadata.polymorphic?
      #
      # @return [ true, false ] True if the relation is polymorphic, false if not.
      #
      # @since 2.0.0.rc.1
      def polymorphic?
        @polymorphic ||= (!!self[:as] || !!self[:polymorphic])
      end

      # Get the relation associated with this metadata.
      #
      # @example Get the relation.
      #   metadata.relation
      #
      # @return [ Proxy ] The relation proxy class.
      #
      # @since 2.1.0
      def relation
        self[:relation]
      end

      # Gets the method name used to set this relation.
      #
      # @example Get the setter.
      #   metadata = Metadata.new(:name => :person)
      #   metadata.setter # => "person="
      #
      # @return [ String ] The name plus "=".
      #
      # @since 2.0.0.rc.1
      def setter
        @setter ||= "#{name.to_s}="
      end

      # Returns the name of the field in which to store the name of the class
      # for the polymorphic relation.
      #
      # @example Get the name of the field.
      #   metadata.inverse_type
      #
      # @return [ String ] The name of the field for storing the type.
      #
      # @since 2.0.0.rc.1
      def type
        @type ||= polymorphic? ? "#{as.to_s}_type" : nil
      end

      # Gets the setter for the field that sets the type of document on a
      # polymorphic relation.
      #
      # @example Get the inverse type setter.
      #   metadata.inverse_type_setter
      #
      # @return [ String ] The name of the setter.
      #
      # @since 2.0.0.rc.1
      def type_setter
        @type_setter ||= type ? "#{type}=" : nil
      end

      # Are we validating this relation automatically?
      #
      # @example Is automatic validation on?
      #   metadata.validate?
      #
      # @return [ true, false ] True unless explictly set to false.
      #
      # @since 2.0.0.rc.1
      def validate?
        unless self[:validate].nil?
          self[:validate]
        else
          self[:validate] = relation.validation_default
        end
      end

      # Is this relation using Mongoid's internal versioning system?
      #
      # @example Is this relation versioned?
      #   metadata.versioned?
      #
      # @return [ true, false ] If the relation uses Mongoid versioning.
      #
      # @since 2.1.0
      def versioned?
        !!self[:versioned]
      end

      # Returns default order for this association.
      #
      # @example Get default order
      #   metadata.order
      #
      # @return [ Criterion::Complex, nil] nil if doesn't set
      #
      # @since 2.1.0
      def order
        self[:order]
      end

      # Is a default order set?
      #
      # @example Is the order set?
      #   metadata.order?
      #
      # @return [ true, false ] If the order is set.
      #
      # @since 2.1.0
      def order?
        !!order
      end

      private

      # Returns the class name for the relation.
      #
      # @example Get the class name.
      #   metadata.classify
      #
      # @return [ String ] If embedded_in, the camelized, else classified.
      #
      # @since 2.0.0.rc.1
      def classify
        macro == :embedded_in ? name.to_s.camelize : name.to_s.classify
      end

      # Get the name of the inverse relation in a cyclic relation.
      #
      # @example Get the cyclic inverse name.
      #
      #   class Role
      #     include Mongoid::Document
      #     embedded_in :parent_role, :cyclic => true
      #     embeds_many :child_roles, :cyclic => true
      #   end
      #
      #   metadata = Metadata.new(:name => :parent_role)
      #   metadata.cyclic_inverse # => "child_roles"
      #
      # @return [ String ] The cyclic inverse name.
      #
      # @since 2.0.0.rc.1
      def cyclic_inverse
        @cyclic_inverse ||= determine_cyclic_inverse
      end

      # Determine the cyclic inverse. Performance improvement with the
      # memoization.
      #
      # @example Determine the inverse.
      #   metadata.determine_cyclic_inverse
      #
      # @return [ String ] The cyclic inverse name.
      #
      # @since 2.0.0.rc.1
      def determine_cyclic_inverse
        underscored = class_name.underscore
        klass.relations.each_pair do |key, meta|
          if key =~ /#{underscored.singularize}|#{underscored.pluralize}/ &&
            meta.relation != relation
            return key.to_sym
          end
        end
      end

      # Determine the value for the relation's foreign key. Performance
      # improvement.
      #
      # @example Determine the foreign key.
      #   metadata.determine_foreign_key
      #
      # @return [ String ] The foreign key.
      #
      # @since 2.0.0.rc.1
      def determine_foreign_key
        return self[:foreign_key].to_s if self[:foreign_key]
        suffix = relation.foreign_key_suffix
        if relation.stores_foreign_key?
          if relation.macro == :references_and_referenced_in_many
            "#{name.to_s.singularize}#{suffix}"
          else
            "#{name}#{suffix}"
          end
        else
          if polymorphic?
            "#{self[:as]}#{suffix}"
          else
            inverse_of ? "#{inverse_of}#{suffix}" : inverse_class_name.foreign_key
          end
        end
      end

      # Determine the inverse relation. Memoizing #inverse_relation and adding
      # this method dropped 5 seconds off the test suite as a performance
      # improvement.
      #
      # @example Determine the inverse.
      #   metadata.determine_inverse_relation
      #
      # @return [ Symbol ] The name of the inverse.
      #
      # @since 2.0.0.rc.1
      def determine_inverse_relation
        default = klass.relations[inverse_klass.name.underscore]
        return default.name if default
        klass.relations.each_pair do |key, meta|
          if meta.class_name == inverse_class_name
            return key.to_sym
          end
        end
        return nil
      end

      # Determine the key for the relation in the attributes.
      #
      # @example Get the key.
      #   metadata.determine_key
      #
      # @return [ String ] The key in the attributes.
      #
      # @since 2.0.0.rc.1
      def determine_key
        return name.to_s if relation.embedded?
        relation.stores_foreign_key? ? foreign_key : "_id"
      end

      # Determine the name of the inverse relation.
      #
      # @example Get the inverse name.
      #   metadata.inverse_relation
      #
      # @return [ Symbol ] The name of the inverse relation.
      #
      # @since 2.0.0.rc.1
      def inverse_relation
        @inverse_relation ||= determine_inverse_relation
      end

      # Infer the name of the inverse relation from the class.
      #
      # @example Get the inverse name
      #   metadata.inverse_name
      #
      # @return [ String ] The inverse class name underscored.
      #
      # @since 2.0.0.rc.1
      def inverse_name
        @inverse_name ||= inverse_klass.name.underscore
      end

      # For polymorphic children, we need to figure out the inverse from the
      # actual instance on the other side, since we cannot know the exact class
      # name to infer it from at load time.
      #
      # @example Find the inverse.
      #   metadata.lookup_inverse(other)
      #
      # @param [ Document ] : The inverse document.
      #
      # @return [ String ] The inverse name.
      #
      # @since 2.0.0.rc.1
      def lookup_inverse(other)
        return nil unless other
        other.class.relations.each_pair do |key, meta|
          return meta.name if meta.as == name
        end
      end
    end
  end
end
