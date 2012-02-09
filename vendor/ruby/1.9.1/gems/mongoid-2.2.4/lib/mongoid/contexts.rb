# encoding: utf-8
require "mongoid/contexts/enumerable"
require "mongoid/contexts/mongo"

module Mongoid
  module Contexts
    extend self

    # Determines the context to be used for this criteria. If the class is an
    # embedded document, then the context will be the array in the has_many
    # association it is in. If the class is a root, then the database itself
    # will be the context.
    #
    # @example Get the context for the criteria.
    #   Contexts.context_for(criteria)
    #
    # @param [ Criteria ] criteria The criteria to use.
    # @param [ true, false ] embedded Whether this is on embedded documents.
    #
    # @return [ Enumerable, Mongo ] The appropriate context.
    def context_for(criteria, embedded = false)
      embedded ? Enumerable.new(criteria) : Mongo.new(criteria)
    end
  end
end
