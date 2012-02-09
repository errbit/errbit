# encoding: utf-8
module Mongoid #:nodoc:

  # This module contains the named scoping behaviour.
  module NamedScope
    extend ActiveSupport::Concern

    included do
      class_attribute :scopes
      self.scopes = {}
    end

    module ClassMethods #:nodoc:

      # Gets either the last scope on the stack or creates a new criteria.
      #
      # @example Get the last or new.
      #   Person.scoping(true)
      #
      # @param [ true, false ] embedded Is this scope for an embedded doc?
      # @param [ true, false ] scoped Are we applying default scoping?
      #
      # @return [ Criteria ] The last scope or a new one.
      #
      # @since 2.0.0
      def criteria(embedded = false, scoped = true)
        scope_stack.last || Criteria.new(self, embedded).tap do |crit|
          return crit.fuse(default_scoping) if default_scoping && scoped
        end
      end

      # Creates a named_scope for the +Document+, similar to ActiveRecord's
      # named_scopes. +NamedScopes+ are proxied +Criteria+ objects that can be
      # chained.
      #
      # @example Create named scopes.
      #
      #   class Person
      #     include Mongoid::Document
      #     field :active, :type => Boolean
      #     field :count, :type => Integer
      #
      #     scope :active, :where => { :active => true }
      #     scope :count_gt_one, :where => { :count.gt => 1 }
      #     scope :at_least_count, lambda { |count| { :where => { :count.gt => count } } }
      #   end
      #
      # @param [ Symbol ] name The name of the scope.
      # @param [ Hash, Criteria ] conditions The conditions of the scope.
      #
      # @since 1.0.0
      def scope(name, conditions = {}, &block)
        name = name.to_sym
        valid_scope_name?(name)
        scopes[name] = Scope.new(conditions, &block)
        (class << self; self; end).class_eval <<-EOT
          def #{name}(*args)
            scope = scopes[:#{name}]
            scope.extend(criteria.fuse(scope.conditions.scoped(*args)))
          end
        EOT
      end
      alias :named_scope :scope

      # Get a criteria object for the class, scoped to the default if defined.
      #
      # @example Get a scoped criteria.
      #   Person.scoped
      #
      # @param [ true, false ] embedded Is the criteria for embedded docs?
      #
      # @return [ Criteria ] The scoped criteria.
      #
      # @since 2.0.0
      def scoped(embedded = false)
        criteria(embedded, true)
      end

      # Initializes and returns the current scope stack.
      #
      # @example Get the scope stack.
      #   Person.scope_stack
      #
      # @return [ Array<Criteria> ] The scope stack.
      #
      # @since 1.0.0
      def scope_stack
        Threaded.scope_stack[object_id] ||= []
      end

      # Get a criteria object for the class, ignoring default scoping.
      #
      # @example Get an unscoped criteria.
      #   Person.scoped
      #
      # @param [ true, false ] embedded Is the criteria for embedded docs?
      #
      # @return [ Criteria ] The unscoped criteria.
      #
      # @since 2.0.0
      def unscoped(embedded = false)
        criteria(embedded, false)
      end

      # Pushes the provided criteria onto the scope stack, and removes it after the
      # provided block is yielded.
      #
      # @example Yield to the criteria.
      #   Person.with_scope(criteria)
      #
      # @param [ Criteria ] criteria The criteria to apply.
      #
      # @return [ Criteria ] The yielded criteria.
      #
      # @since 1.0.0
      def with_scope(criteria)
        scope_stack = self.scope_stack
        scope_stack << criteria
        begin
          yield criteria
        ensure
          scope_stack.pop
        end
      end

    protected

      # Warns if overriding another scope or method.
      #
      # @example Warn if name exists.
      #   Model.valid_scope_name?("test")
      #
      # @param [ String, Symbol ] name The name of the scope.
      def valid_scope_name?(name)
        if scopes[name] || respond_to?(name, true)
          if Mongoid.logger
            Mongoid.logger.warn(
              "Creating scope :#{name}. " +
              "Overwriting existing method #{self.name}.#{name}."
            )
          end
        end
      end
    end
  end
end
