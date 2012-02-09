# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # This error is raised when trying to access a Mongo::Collection from an
    # embedded document.
    #
    # @example Create the error.
    #   InvalidCollection.new(Address)
    class InvalidCollection < MongoidError
      def initialize(klass)
        super(
          translate("invalid_collection", { :klass => klass.name })
        )
      end
    end
  end
end
