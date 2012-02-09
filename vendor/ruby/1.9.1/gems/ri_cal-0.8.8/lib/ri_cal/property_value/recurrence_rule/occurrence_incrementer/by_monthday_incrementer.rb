module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
        class ByMonthdayIncrementer < ByNumberedDayIncrementer #:nodoc:
          def self.for_rrule(rrule)
            conditional_incrementer(rrule, :bymonthday, DailyIncrementer)
          end
          
          def scope_of(date_time)
            date_time.month
          end

          def start_of_cycle(date_time)
            date_time.change(:day => 1)
          end

          def advance_cycle(date_time)
            first_day_of_month(advance_month(date_time))
          end

          def end_of_occurrence(date_time)
            date_time.end_of_day
          end
        end
      end
    end
  end
end