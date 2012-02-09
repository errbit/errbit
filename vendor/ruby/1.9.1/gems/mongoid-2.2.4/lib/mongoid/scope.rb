# encoding: utf-8
module Mongoid #:nodoc:
  # This module handles behaviour for defining scopes on classes.
  class Scope
    attr_reader :conditions, :extensions

    # Create the new +Scope+. If a block is passed in, this Scope will store
    # the block for future calls to #extend.
    #
    # @example Create a new scope.
    #   Scope.new(:title => "Sir")
    #
    # @param [ Hash ] conditions The scoping limitations.
    def initialize(conditions = {}, &block)
      @conditions = conditions
      @extensions = Module.new(&block) if block_given?
    end

    # Extend a supplied criteria.
    #
    # @example Extend the criteria.
    #   scope.extend(criteria)
    #
    # @param [ Criteria } criteria A mongoid criteria to extend.
    #
    # @return [ Criteria ] The new criteria object.
    def extend(criteria)
      extensions ? criteria.extend(extensions) : criteria
    end
  end
end
