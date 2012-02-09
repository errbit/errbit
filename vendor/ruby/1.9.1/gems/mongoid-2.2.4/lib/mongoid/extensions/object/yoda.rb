# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Object #:nodoc:

      # This module behaves like the master jedi.
      module Yoda #:nodoc:

        # Do or do not, there is no try. -- Yoda.
        #
        # @example Do or do not.
        #   object.do_or_do_not(:use, "The Force")
        #
        # @param [ String, Symbol ] name The method name.
        # @param [ Array ] *args The arguments.
        #
        # @return [ Object, nil ] The result of the method call or nil if the
        #   method does not exist.
        #
        # @since 2.0.0.rc.1
        def do_or_do_not(name, *args)
          respond_to?(name) ? send(name, *args) : nil
        end

        # You must unlearn what you have learned. -- Yoda
        #
        # @example You must perform this execution.
        #   object.you_must(:use, "The Force")
        #
        # @param [ String, Symbol ] name The method name.
        # @param [ Array ] *args The arguments.
        #
        # @return [ Object, nil ] The result of the method call or nil if the
        #   method does not exist. Nil if the object is frozen.
        #
        # @since 2.2.1
        def you_must(name, *args)
          frozen? ? nil : do_or_do_not(name, *args)
        end
      end
    end
  end
end
