module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
        class ByWeekNoIncrementer < ListIncrementer #:nodoc:
          attr_reader :wkst
          # include WeeklyBydayMethods

          def initialize(rrule, list, sub_cycle_incrementer)
            @wkst = rrule.wkst_day
            super(rrule, list, sub_cycle_incrementer)
          end

          def self.for_rrule(rrule)
            conditional_incrementer(rrule, :byweekno, WeeklyIncrementer)
          end

          def weeknum_incrementer?
            true
          end
          
          def unneeded?(candidate)
            false
          end

          def first_within_outer_cycle(previous_occurrence, outer_range)
            new_range_start = outer_range.first
            new_range_end = new_range_start.end_of_iso_year(wkst)
            super(previous_occurrence, outer_range.first..new_range_end)
          end

          def start_of_cycle(date_time)
            result = date_time.at_start_of_iso_year(wkst)
            result
          end

          def occurrences_for(date_time)
            iso_year, year_start = *date_time.iso_year_and_week_one_start(wkst)
            week_one_occurrence = date_time.change(
              :year => year_start.year,
              :month => year_start.month,
              :day => year_start.day
            )
            weeks_in_year_plus_one = week_one_occurrence.iso_weeks_in_year(wkst)
            weeks = list.map {|recurring_weeknum|
              wk_num = recurring_weeknum.ordinal
              (wk_num > 0) ? wk_num : weeks_in_year_plus_one + wk_num
              }.uniq.sort
            weeks.map {|wk_num| week_one_occurrence.advance(:days => (wk_num - 1) * 7)}
          end

          def candidate_acceptable?(candidate)
            list.include?(candidate.iso_week_num(wkst))
          end

          def advance_cycle(date_time)
            date_time.at_start_of_next_iso_year(wkst)
          end

          def end_of_occurrence(date_time)
            date_time.end_of_week_with_wkst(wkst)
          end
        end
      end
    end
  end
end