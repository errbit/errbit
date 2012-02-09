module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      class OccurrenceIncrementer # :nodoc:
        #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
        #
        class NullSubCycleIncrementer #:nodoc:
          def self.next_time(previous)
            nil
          end

          def self.add_outer_incrementer(incrementer)
          end
          
          def self.unneeded?(candidate)
            true
          end

          def self.first_within_outer_cycle(previous_occurrence, outer_cycle_range)
            outer_cycle_range.first
          end

          def self.first_sub_occurrence(previous_occurrence, outer_cycle_range)
            nil
          end

          def self.cycle_adjust(date_time)
            date_time
          end

          def self.to_s
            "NULL-INCR"
          end

          def inspect
            to_s
          end
        end
      end
    end
  end
end

