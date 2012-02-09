module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
         class BySecondIncrementer < ListIncrementer #:nodoc:

          def self.for_rrule(rrule)
            conditional_incrementer(rrule, :bysecond, SecondlyIncrementer)
          end

          def varying_time_attribute
            :sec
          end

          def start_of_cycle(date_time)
            date_time.start_of_minute
          end

          def advance_cycle(date_time)
            date_time.advance(:minutes => 1).start_of_minute
          end

          def end_of_occurrence(date_time)
            date_time
          end
        end
      end
    end
  end
end