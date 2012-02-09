# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Object #:nodoc:

      # This module has object checks in it.
      module Checks #:nodoc:

        # Since Active Support's blank? check looks to see if the object
        # responds to #empty? and will call it if it does, we need another way
        # to check if the object is empty or nil in case the user has defined a
        # field called "empty" on the document.
        #
        # @example Is the array vacant?
        #   [].vacant?
        #
        # @example Is the object vacant?
        #   nil.vacant?
        #
        # @return [ true, false ] True if empty or nil, false if not.
        #
        # @since 2.0.2
        def _vacant?
          is_a?(::Array) || is_a?(::String) ? empty? : !self
        end
      end
    end
  end
end
