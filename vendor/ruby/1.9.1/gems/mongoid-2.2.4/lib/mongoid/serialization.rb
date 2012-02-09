# encoding: utf-8
module Mongoid # :nodoc:

  # This module provides the extra behaviour for including relations in JSON
  # and XML serialization.
  module Serialization
    extend ActiveSupport::Concern
    include ActiveModel::Serialization

    # Gets the document as a serializable hash, used by ActiveModel's JSON and
    # XML serializers. This override is just to be able to pass the :include
    # and :except options to get associations in the hash.
    #
    # @example Get the serializable hash.
    #   document.serializable_hash
    #
    # @example Get the serializable hash with options.
    #   document.serializable_hash(:include => :addresses)
    #
    # @param [ Hash ] options The options to pass.
    #
    # @option options [ Symbol ] :include What relations to include
    # @option options [ Symbol ] :only Limit the fields to only these.
    # @option options [ Symbol ] :except Dont include these fields.
    #
    # @return [ Hash ] The document, ready to be serialized.
    #
    # @since 2.0.0.rc.6
    def serializable_hash(options = nil)
      options ||= {}
      super(options).tap do |attrs|
        serialize_relations(attrs, options) if options[:include]
      end
    end

    class << self

      # Serialize the provided object into a Mongo friendly value, using the
      # field serialization method for the passed in type. If no type is
      # given then we assume generic object serialization, which just returns
      # the value itself.
      #
      # @example Mongoize the object.
      #   Mongoid::Serialization.mongoize(time, Time)
      #
      # @param [ Object ] object The object to convert.
      # @param [ Class ] klass The type of the object.
      #
      # @return [ Object ] The converted object.
      #
      # @since 2.1.0
      def mongoize(object, klass = Object)
        Fields::Mappings.for(klass).instantiate(:mongoize).serialize(object)
      end
    end

    private

    # For each of the provided include options, get the relation needed and
    # provide it in the hash.
    #
    # @example Serialize the included relations.
    #   document.serialize_relations({}, :include => :addresses)
    #
    # @param [ Hash ] attributes The attributes to serialize.
    # @param [ Hash ] options The serialization options.
    #
    # @option options [ Symbol ] :include What relations to include
    # @option options [ Symbol ] :only Limit the fields to only these.
    # @option options [ Symbol ] :except Dont include these fields.
    #
    # @since 2.0.0.rc.6
    def serialize_relations(attributes = {}, options = {})
      inclusions = options[:include]
      relation_names(inclusions).each do |name|
        metadata = relations[name.to_s]
        relation = send(metadata.name)
        if relation
          attributes[metadata.name.to_s] =
            relation.serializable_hash(relation_options(inclusions, options, name))
        end
      end
    end

    # Since the inclusions can be a hash, symbol, or array of symbols, this is
    # provided as a convenience to parse out the names.
    #
    # @example Get the relation names.
    #   document.relation_names(:include => [ :addresses ])
    #
    # @param [ Hash, Symbol, Array<Symbol ] inclusions The inclusions.
    #
    # @return [ Array<Symbol> ] The names of the included relations.
    #
    # @since 2.0.0.rc.6
    def relation_names(inclusions)
      inclusions.is_a?(Hash) ? inclusions.keys : Array.wrap(inclusions)
    end

    # Since the inclusions can be a hash, symbol, or array of symbols, this is
    # provided as a convenience to parse out the options.
    #
    # @example Get the relation options.
    #   document.relation_names(:include => [ :addresses ])
    #
    # @param [ Hash, Symbol, Array<Symbol ] inclusions The inclusions.
    # @param [ Symbol ] name The name of the relation.
    #
    # @return [ Hash ] The options for the relation.
    #
    # @since 2.0.0.rc.6
    def relation_options(inclusions, options, name)
      if inclusions.is_a?(Hash)
        inclusions[name]
      else
        { :except => options[:except], :only => options[:only] }
      end
    end
  end
end
