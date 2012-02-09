# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when attempting to call create or create! through a
    # references_many when the parent document has not been saved. This
    # prevents the child from getting presisted and immediately being orphaned.
    class UnsavedDocument < MongoidError

      attr_reader :base, :document

      def initialize(base, document)
        @base, @document = base, document
        super(
          translate(
            "unsaved_document",
            { :base => base.class.name, :document => document.class.name }
          )
        )
      end
    end
  end
end
