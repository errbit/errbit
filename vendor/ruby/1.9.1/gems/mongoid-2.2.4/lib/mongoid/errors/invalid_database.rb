# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when the database connection has not been set up properly, either
    # by attempting to set an object on the db that is not a +Mongo::DB+, or
    # not setting anything at all.
    #
    # @example Create the error.
    #   InvalidDatabase.new("Not a DB")
    class InvalidDatabase < MongoidError
      def initialize(database)
        super(
          translate("invalid_database", { :name => database.class.name })
        )
      end
    end
  end
end
