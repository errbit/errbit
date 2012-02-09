# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This module contains all the behaviour related to accessing relations
    # through the getters and setters, and how to delegate to builders to
    # create new ones.
    module Accessors
      extend ActiveSupport::Concern

      # Builds the related document and creates the relation unless the
      # document is nil, then sets the relation on this document.
      #
      # @example Build the relation.
      #   person.build(:addresses, { :id => 1 }, metadata)
      #
      # @param [ String, Symbol ] name The name of the relation.
      # @param [ Hash, BSON::ObjectId ] object The id or attributes to use.
      # @param [ Metadata ] metadata The relation's metadata.
      # @param [ true, false ] building If we are in a build operation.
      #
      # @return [ Proxy ] The relation.
      #
      # @since 2.0.0.rc.1
      def build(name, object, metadata, options = {})
        relation = create_relation(object, metadata, options[:loading])
        set_relation(name, relation)
      end

      # Create a relation from an object and metadata.
      #
      # @example Create the relation.
      #   person.create_relation(document, metadata)
      #
      # @param [ Document, Array<Document ] object The relation target.
      # @param [ Metadata ] metadata The relation metadata.
      #
      # @return [ Proxy ] The relation.
      #
      # @since 2.0.0.rc.1
      def create_relation(object, metadata, loading = false)
        type = @attributes[metadata.inverse_type]
        target = metadata.builder(object, loading).build(type)
        target ? metadata.relation.new(self, target, metadata) : nil
      end

      # Determines if the relation exists or not.
      #
      # @example Does the relation exist?
      #   person.relation_exists?(:people)
      #
      # @param [ String ] name The name of the relation to check.
      #
      # @return [ true, false ] True if set and not nil, false if not.
      #
      # @since 2.0.0.rc.1
      def relation_exists?(name)
        ivar(name)
      end

      # Set the supplied relation to an instance variable on the class with the
      # provided name. Used as a helper just for code cleanliness.
      #
      # @example Set the proxy on the document.
      #   person.set(:addresses, addresses)
      #
      # @param [ String, Symbol ] name The name of the relation.
      # @param [ Proxy ] relation The relation to set.
      #
      # @return [ Proxy ] The relation.
      #
      # @since 2.0.0.rc.1
      def set_relation(name, relation)
        instance_variable_set("@#{name}", relation)
      end

      module ClassMethods #:nodoc:

        # Defines the getter for the relation. Nothing too special here: just
        # return the instance variable for the relation if it exists or build
        # the thing.
        #
        # @example Set up the getter for the relation.
        #   Person.getter("addresses", metadata)
        #
        # @param [ String, Symbol ] name The name of the relation.
        # @param [ Metadata ] metadata The metadata for the relation.
        #
        # @return [ Class ] The class being set up.
        #
        # @since 2.0.0.rc.1
        def getter(name, metadata)
          tap do
            define_method(name) do |*args|
              reload, variable = args.first, "@#{name}"
              if instance_variable_defined?(variable) && !reload
                instance_variable_get(variable)
              else
                building do
                  build(name, attributes[metadata.key], metadata, :loading => true)
                end
              end
            end
          end
        end

        # Defines the setter for the relation. This does a few things based on
        # some conditions. If there is an existing association, a target
        # substitution will take place, otherwise a new relation will be
        # created with the supplied target.
        #
        # @example Set up the setter for the relation.
        #   Person.setter("addresses", metadata)
        #
        # @param [ String, Symbol ] name The name of the relation.
        # @param [ Metadata ] metadata The metadata for the relation.
        #
        # @return [ Class ] The class being set up.
        #
        # @since 2.0.0.rc.1
        def setter(name, metadata)
          tap do
            define_method("#{name}=") do |object|
              if relation_exists?(name) || metadata.many? ||
                (object.blank? && send(name))
                set_relation(name, send(name).substitute(object.substitutable))
              else
                build(name, object.substitutable, metadata)
              end
            end
          end
        end
      end
    end
  end
end
