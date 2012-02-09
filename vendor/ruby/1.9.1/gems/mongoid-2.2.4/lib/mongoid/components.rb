# encoding: utf-8
module Mongoid #:nodoc
  module Components #:nodoc
    extend ActiveSupport::Concern

    # All modules that a +Document+ is composed of are defined in this
    # module, to keep the document class from getting too cluttered.
    included do
      extend ActiveModel::Translation
      extend Mongoid::Finders
    end

    include ActiveModel::Conversion
    include ActiveModel::MassAssignmentSecurity
    include ActiveModel::Naming
    include ActiveModel::Observing
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml
    include Mongoid::Atomic
    include Mongoid::Attributes
    include Mongoid::Collections
    include Mongoid::Copyable
    include Mongoid::DefaultScope
    include Mongoid::Dirty
    include Mongoid::Extras
    include Mongoid::Fields
    include Mongoid::Hierarchy
    include Mongoid::Indexes
    include Mongoid::Inspection
    include Mongoid::JSON
    include Mongoid::Keys
    include Mongoid::Matchers
    include Mongoid::NamedScope
    include Mongoid::NestedAttributes
    include Mongoid::Persistence
    include Mongoid::Relations
    include Mongoid::Safety
    include Mongoid::Serialization
    include Mongoid::Sharding
    include Mongoid::State
    include Mongoid::Validations
    include Mongoid::Callbacks
    include Mongoid::MultiDatabase

    MODULES = [
      Mongoid::Atomic,
      Mongoid::Attributes,
      Mongoid::Collections,
      Mongoid::Copyable,
      Mongoid::DefaultScope,
      Mongoid::Dirty,
      Mongoid::Extras,
      Mongoid::Fields,
      Mongoid::Hierarchy,
      Mongoid::Indexes,
      Mongoid::Inspection,
      Mongoid::JSON,
      Mongoid::Keys,
      Mongoid::Matchers,
      Mongoid::NamedScope,
      Mongoid::NestedAttributes,
      Mongoid::Persistence,
      Mongoid::Relations,
      Mongoid::Safety,
      Mongoid::Serialization,
      Mongoid::Sharding,
      Mongoid::State,
      Mongoid::Validations,
      Mongoid::Callbacks,
      Mongoid::MultiDatabase,
    ]

    class << self

      # Get a list of methods that would be a bad idea to define as field names
      # or override when including Mongoid::Document.
      #
      # @example Bad thing!
      #   Mongoid::Components.prohibited_methods
      #
      # @return [ Array<Symbol> ]
      #
      # @since 2.1.8
      def prohibited_methods
        @prohibited_methods ||= MODULES.inject([]) do |methods, mod|
          methods.tap do |mets|
            mets << mod.instance_methods.map{ |m| m.to_sym }
          end
        end.flatten
      end
    end
  end
end
