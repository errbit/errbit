# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:

      # Expands complex criterion into mongodb selectors.
      module CriteriaHelpers

        # Expand the complex criteria into a MongoDB compliant selector hash.
        #
        # @example Convert the criterion.
        #   {}.expand_complex_criteria
        #
        # @return [ Hash ] The mongo selector.
        #
        # @since 1.0.0
        def expand_complex_criteria
          {}.tap do |hsh|
            each_pair do |k,v|
              case k
              when Mongoid::Criterion::Complex
                hsh[k.key] ||= {}
                hsh[k.key].merge!({"$#{k.operator}" => v})
              else
                hsh[k] = v
              end
            end
          end
        end
      end
    end
  end
end
