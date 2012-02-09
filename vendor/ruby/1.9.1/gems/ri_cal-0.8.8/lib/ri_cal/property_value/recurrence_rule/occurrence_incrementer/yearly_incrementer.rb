module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
         class YearlyIncrementer < FrequencyIncrementer #:nodoc:

           attr_reader :wkst

           def initialize(rrule, sub_cycle_incrementer)
             @wkst = rrule.wkst_day
             super(rrule, sub_cycle_incrementer)
           end

           def self.from_rrule(rrule, start_time)
             conditional_incrementer(rrule, "YEARLY", ByMonthIncrementer)
           end

           def advance_what
             :years
           end

           def step(date_time)
             if contains_weeknum_incrementer?
               result = date_time
               multiplier.times do
                 result = result.at_start_of_next_iso_year(wkst)
               end
               result
             else
               super(date_time)
             end
           end

           def start_of_cycle(date_time)
             if contains_weeknum_incrementer?
               date_time.at_start_of_iso_year(wkst)
             elsif contains_daily_incrementer?
               date_time.change(:month => 1, :day => 1)
             else
               date_time.change(:month => 1)
             end
           end

           def end_of_occurrence(date_time)
             if contains_weeknum_incrementer?
               date_time.end_of_iso_year(wkst)
             else
               date_time.end_of_year
             end
           end
        end
      end
    end
  end
end