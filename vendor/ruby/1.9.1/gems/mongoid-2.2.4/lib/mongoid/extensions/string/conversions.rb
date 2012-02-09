# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module String #:nodoc:
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        # Convert the string to an array with the string in it.
        #
        # @example Convert the string to an array.
        #   "Testing".to_a
        #
        # @return [ Array ] An array with only the string in it.
        #
        # @since 1.0.0
        def to_a
          [ self ]
        end
      end
    end
  end
end
