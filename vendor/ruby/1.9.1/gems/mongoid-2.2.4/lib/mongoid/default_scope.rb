# encoding: utf-8
module Mongoid #:nodoc:

  # This module handles functionality for creating default scopes.
  module DefaultScope
    extend ActiveSupport::Concern

    included do
      class_attribute :default_scoping
    end

    module ClassMethods #:nodoc:

      # Creates a default_scope for the +Document+, similar to ActiveRecord's
      # default_scope. +DefaultScopes+ are proxied +Criteria+ objects that are
      # applied by default to all queries for the class.
      #
      # @example Create a default scope.
      #
      #   class Person
      #     include Mongoid::Document
      #     field :active, :type => Boolean
      #     field :count, :type => Integer
      #
      #     default_scope :where => { :active => true }
      #   end
      #
      # @param [ Hash ] conditions The conditions to create with.
      #
      # @since 2.0.0.rc.1
      def default_scope(conditions = {})
        self.default_scoping = Scope.new(conditions).conditions.scoped
      end
    end
  end
end
