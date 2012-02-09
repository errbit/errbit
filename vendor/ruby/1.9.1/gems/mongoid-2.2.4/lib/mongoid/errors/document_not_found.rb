# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when querying the database for a document by a specific id which
    # does not exist. If multiple ids were passed then it will display all of
    # those.
    #
    # @example Create the error.
    #   DocumentNotFound.new(Person, ["1", "2"])
    class DocumentNotFound < MongoidError

      attr_reader :klass, :identifiers

      def initialize(klass, ids)
        @klass = klass
        @identifiers = ids.is_a?(Array) ? ids.join(", ") : ids

        super(
          translate(
            "document_not_found",
            { :klass => klass.name, :identifiers => identifiers }
          )
        )
      end
    end
  end
end
