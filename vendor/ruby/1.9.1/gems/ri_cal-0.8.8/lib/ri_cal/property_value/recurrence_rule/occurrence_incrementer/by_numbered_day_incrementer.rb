module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
        class ByNumberedDayIncrementer < ListIncrementer #:nodoc:

          def daily_incrementer?
            true
          end
          
          def unneeded?(candidate)
            list.length == 1 && list.first.fixed_day?
          end

          def occurrences_for(date_time)
            if occurrences && @scoping_value == scope_of(date_time)
               occurrences
            else
              @scoping_value = scope_of(date_time)
              self.occurrences = list.map {|numbered_day| numbered_day.target_date_time_for(date_time)}.uniq.sort
              occurrences
            end
          end

          def end_of_occurrence(date_time)
            date_time.end_of_day
          end

          def candidate_acceptable?(candidate)
            list.any? {|by_part| by_part.include?(candidate)}
          end
        end
      end
    end
  end
end