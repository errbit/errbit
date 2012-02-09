# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # This error is raised when attempting to eager load a many to many
    # relation.
    class EagerLoad < MongoidError

      attr_reader :name

      # Create the new eager load error.
      #
      # @example Create the new eager load error.
      #   EagerLoad.new(:preferences)
      #
      # @param [ Symbol ] name The name of the relation.
      #
      # @since 2.2.0
      def initialize(name)
        @name = name
        super(translate("eager_load", { :name => name }))
      end
    end
  end
end
