module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
        class HourlyIncrementer < FrequencyIncrementer #:nodoc:
          def self.for_rrule(rrule)
            conditional_incrementer(rrule, "HOURLY", ByMinuteIncrementer)
          end

          def advance_what
            :hours
          end

          def end_of_occurrence(date_time)
            date_time.end_of_hour
          end
        end
      end
    end
  end
end