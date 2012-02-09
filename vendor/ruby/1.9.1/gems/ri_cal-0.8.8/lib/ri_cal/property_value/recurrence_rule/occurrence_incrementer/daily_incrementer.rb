module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
        class DailyIncrementer < FrequencyIncrementer #:nodoc:

          def self.for_rrule(rrule)
            conditional_incrementer(rrule, "DAILY", OccurrenceIncrementer::ByHourIncrementer)
          end

          def daily_incrementer?
            true
          end

          def advance_what
            :days
          end

          def end_of_occurrence(date_time)
            date_time.end_of_day
          end
        end
      end
    end
  end
end