# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:

    # This module defines criteria behavior for building documents for
    # specified conditions.
    module Builder

      # Build a document given the selector and return it.
      # Complex criteria, such as $in and $or operations will get ignored.
      #
      # @example build the document.
      #   Person.where(:title => "Sir").build
      #
      # @example Build with selectors getting ignored.
      #   Person.where(:age.gt => 5).build
      #
      # @return [ Document ] A non-persisted document.
      #
      # @since 2.0.0
      def build(attrs = {})
        klass.new(
          selector.inject(attrs) do |hash, (key, value)|
            hash.tap do |attrs|
              unless key.to_s =~ /\$/ || value.is_a?(Hash)
                attrs[key] = value
              end
            end
          end
        )
      end
    end
  end
end
