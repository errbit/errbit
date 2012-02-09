# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Array #:nodoc:

      # This module contains deletion helpers for arrays.
      module Deletion

        # Delete the first object in the array that is equal to the supplied
        # object and return it. This is much faster than performing a standard
        # delete for large arrays ince it attempt to delete multiple in the
        # other.
        #
        # @example Delete the first object.
        #   [ "1", "2", "1" ].delete_one("1")
        #
        # @param [ Object ] object The object to delete.
        #
        # @return [ Object ] The deleted object.
        #
        # @since 2.1.0
        def delete_one(object)
          position = index(object)
          position ? delete_at(position) : nil
        end
      end
    end
  end
end
