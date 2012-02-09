# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # This error is raised when trying to create a field that conflicts with
    # a Mongoid internal attribute or method.
    #
    # @example Create the error.
    #   InvalidField.new('collection')
    class InvalidField < MongoidError
      def initialize(name)
        super(
          translate("invalid_field", { :name => name })
        )
      end
    end
  end
end
