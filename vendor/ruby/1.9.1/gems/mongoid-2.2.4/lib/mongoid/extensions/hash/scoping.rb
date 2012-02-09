# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:

      # Adds functionality for criteria scoping/merging.
      module Scoping

        # Get the hash scoped for criteria merges.
        #
        # @example Get the hash.
        #   { :field => "value" }.scoped
        #
        # @param [ Array ] args The arguments (ignored).
        #
        # @return [ Hash ] The hash unmodified.
        #
        # @since 1.0.0
        def scoped(*args)
          self
        end
      end
    end
  end
end
