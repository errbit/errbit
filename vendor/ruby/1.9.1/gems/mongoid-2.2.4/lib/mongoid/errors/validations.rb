# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when a persistence method ending in ! fails validation. The message
    # will contain the full error messages from the +Document+ in question.
    #
    # @example Create the error.
    #   Validations.new(person.errors)
    class Validations < MongoidError
      attr_reader :document
      def initialize(document)
        @document = document
        super(
          translate(
            "validations",
            { :errors => document.errors.full_messages.join(", ") }
          )
        )
      end
    end
  end
end
