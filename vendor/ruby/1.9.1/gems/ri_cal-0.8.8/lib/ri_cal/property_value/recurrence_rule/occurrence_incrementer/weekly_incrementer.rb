module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
        class WeeklyIncrementer < FrequencyIncrementer #:nodoc:

          attr_reader :wkst

          # include WeeklyBydayMethods

          def initialize(rrule, parent)
            @wkst = rrule.wkst_day
            super(rrule, parent)
          end

          def self.for_rrule(rrule)
            conditional_incrementer(rrule, "WEEKLY", ByDayIncrementer)
          end

          def multiplier
            7
          end

          def advance_what
            :days
          end

          def end_of_occurrence(date_time)
            date_time.end_of_week_with_wkst(wkst)
          end
        end
      end
    end
  end
end