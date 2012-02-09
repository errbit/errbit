# encoding: utf-8
module Mongoid #:nodoc:
  module Contexts #:nodoc:
    class Enumerable
      class Sort
        attr_reader :value, :direction

        # Create a new sorting object. This requires a value and a sort
        # direction of +:asc+ or +:desc+.
        def initialize(value, direction)
          @value     = value
          @direction = direction
        end

        # Return +true+ if the direction is +:asc+, otherwise false.
        def ascending?
          direction == :asc
        end

        # Compare two +Sort+ objects against each other, taking into
        # consideration the direction of the sorting.
        def <=>(other)
          cmp = compare(value, other.value)
          ascending? ? cmp : cmp * -1
        end

        private

        # Compare two values allowing for nil values.
        def compare(a, b)
          case
          when a.nil?
            b.nil? ? 0 : 1
          when b.nil?
            -1
          else
            a <=> b
          end
        end
      end
    end
  end
end
