# encoding: utf-8
module Mongoid #:nodoc
  module Indexes #:nodoc
    extend ActiveSupport::Concern

    included do
      cattr_accessor :index_options
      self.index_options = {}
    end

    module ClassMethods #:nodoc

      # Send the actual index creation comments to the MongoDB driver
      #
      # @example Create the indexes for the class.
      #   Person.create_indexes
      def create_indexes
        return unless index_options
        current_collection = self._collection || set_collection
        index_options.each_pair do |name, options|
          current_collection.create_index(name, options)
        end
      end

      # Add the default indexes to the root document if they do not already
      # exist. Currently this is only _type.
      #
      # @example Add Mongoid internal indexes.
      #   Person.add_indexes
      def add_indexes
        if hereditary? && !index_options[:_type]
          self.index_options[:_type] = {:unique => false, :background => true}
        end
        create_indexes if Mongoid.autocreate_indexes
      end

      # Adds an index on the field specified. Options can be :unique => true or
      # :unique => false. It will default to the latter.
      #
      # @example Create a basic index.
      #   class Person
      #     include Mongoid::Document
      #     field :name, :type => String
      #     index :name, :background => true
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Hash ] options The index options.
      def index(name, options = { :unique => false })
        self.index_options[name] = options
        create_indexes if Mongoid.autocreate_indexes
      end
    end
  end
end
