# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when trying to get or set a value for a defined field, where the
    # type of the object does not match the defined field type.
    #
    # @example Create the error.
    #   InvalidType.new(Array, "Not an Array")
    class InvalidType < MongoidError
      def initialize(klass, value)
        super(
          translate(
            "invalid_type",
            {
              :klass => klass.name,
              :other => value.class.name,
              :value => value.inspect
            }
          )
        )
      end
    end
  end
end
