# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module String #:nodoc:

      # This module has object checks in it.
      module Checks #:nodoc:
        attr_accessor :unconvertable_to_bson

        # Is the object not to be converted to bson on criteria creation?
        #
        # @example Is the object unconvertable?
        #   object.unconvertable_to_bson?
        #
        # @return [ true, false ] If the object is unconvertable.
        #
        # @since 2.2.1
        def unconvertable_to_bson?
          !!@unconvertable_to_bson
        end
      end
    end
  end
end
