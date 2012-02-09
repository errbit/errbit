module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
        class ByMinuteIncrementer < ListIncrementer #:nodoc:
          def self.for_rrule(rrule)
            conditional_incrementer(rrule, :byminute, MinutelyIncrementer)
          end

          def advance_cycle(date_time)
            date_time.advance(:hours => 1).start_of_hour
          end

          def start_of_cycle(date_time)
            date_time.change(:min => 0)
          end

          def end_of_occurrence(date_time)
            date_time.end_of_minute
          end

          def varying_time_attribute
            :min
          end
        end

      end
    end
  end
end