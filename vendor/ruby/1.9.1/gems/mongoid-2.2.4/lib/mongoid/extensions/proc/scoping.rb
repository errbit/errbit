# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Proc #:nodoc:

      # Adds functionality for criteria scoping/merging.
      module Scoping

        # Get the proc scoped for criteria merges.
        #
        # @example Get the hash.
        #   proc.scoped
        #
        # @param [ Array ] args The arguments to delegate to the proc.
        #
        # @return [ Object ] The result of the proc call.
        #
        # @since 1.0.0
        def scoped(*args)
          call(*args).scoped
        end
      end
    end
  end
end
