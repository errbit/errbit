module Mongoid #:nodoc
  module Errors #:nodoc

    # This error is raised when trying to create set nested records above the
    # specified :limit
    #
    # @example Create the error.
    #   TooManyNestedAttributeRecords.new('association', limit)
    class TooManyNestedAttributeRecords < MongoidError
      def initialize(association, limit)
        super(
          translate(
            "too_many_nested_attribute_records",
            { :association => association, :limit => limit }
          )
        )
      end
    end
  end
end
