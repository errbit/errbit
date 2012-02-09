module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
        class ByHourIncrementer < ListIncrementer #:nodoc:
          def self.for_rrule(rrule)
            conditional_incrementer(rrule, :byhour, HourlyIncrementer)
          end

          def start_of_cycle(date_time)
            date_time.change(:hour => 0)
          end

          def varying_time_attribute
            :hour
          end

          def advance_cycle(date_time)
            first_hour_of_day(advance_day(date_time))
          end

          def end_of_occurrence(date_time)
            date_time.end_of_hour
          end
        end
      end
    end
  end
end