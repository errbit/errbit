module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
        class ByMonthIncrementer < ListIncrementer #:nodoc:

          def self.for_rrule(rrule)
            conditional_incrementer(rrule, :bymonth, MonthlyIncrementer)
          end

          def occurrences_for(date_time)
            if contains_daily_incrementer?
              list.map {|value| date_time.change(:month => value, :day => 1)}
            else
              list.map {|value| date_time.in_month(value)}
            end
          end

          def range_advance(date_time)
            advance_year(date_time)
          end

          def start_of_cycle(date_time)
            if contains_daily_incrementer?
              date_time.change(:month => 1, :day => 1)
            else
              date_time.change(:month => 1)
            end
          end

          def varying_time_attribute
            :month
          end

          def advance_cycle(date_time)
            if contains_daily_incrementer?
              first_day_of_year(advance_year(date_time))
            else
              advance_year(date_time).change(:month => 1)
            end
          end

          def end_of_occurrence(date_time)
            date_time.end_of_month
          end
        end
      end
    end
  end
end