module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
        class ByYeardayIncrementer < ByNumberedDayIncrementer #:nodoc:
          def self.for_rrule(rrule)
            conditional_incrementer(rrule, :byyearday, ByMonthdayIncrementer)
          end

          def start_of_cycle(date_time)
            date_time.change(:month => 1, :day => 1)
          end

          def scope_of(date_time)
            date_time.year
          end

          def advance_cycle(date_time)
            first_day_of_year(advance_year(date_time))
          end

          def end_of_occurrence(date_time)
            date_time.end_of_day
          end
        end
      end
    end
  end
end