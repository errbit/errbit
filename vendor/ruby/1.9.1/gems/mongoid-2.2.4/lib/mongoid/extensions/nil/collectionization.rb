# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Nil #:nodoc:

      # This module safeguards collection access on anonymous classes.
      module Collectionization

        # Get the name of a nil collection.
        #
        # @example Get the nil name.
        #   nil.collectionize
        #
        # @return [ String ] A blank string.
        #
        # @since 1.0.0
        def collectionize
          to_s.collectionize
        end
      end
    end
  end
end
