# encoding: utf-8
module Mongoid #:nodoc:

  # Adds multiple database support to documents.
  module MultiDatabase
    extend ActiveSupport::Concern

    module ClassMethods #:nodoc:

      # Gets the database from the class.
      #
      # @example Get the database.
      #   Model.database
      #
      # @return [ Mongo::DB ] The database.
      def database; @database end

      # Set the database name.
      #
      # @example Set the database name.
      #   Model.set_database(:testing)
      #
      # @param [ Symbol ] name The database name.
      #
      # @return [ String ] The database name.
      def set_database(name)
        @database = name.to_s
      end
    end
  end
end
