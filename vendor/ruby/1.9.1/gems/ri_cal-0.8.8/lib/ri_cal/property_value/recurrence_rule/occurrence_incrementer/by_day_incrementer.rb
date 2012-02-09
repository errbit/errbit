module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:
        class ByDayIncrementer < ListIncrementer #:nodoc:

          def initialize(rrule, list, by_monthday_list, by_yearday_list, parent)
            super(rrule, list, parent)
            @monthday_filters = by_monthday_list
            @yearday_filters = by_yearday_list
            @by_day_scope = rrule.by_day_scope

            case rrule.by_day_scope
            when :yearly
              @cycle_advance_proc = lambda {|date_time| first_day_of_year(advance_year(date_time))}
              @current_proc = lambda {|date_time| same_year?(current, date_time)}
              @first_day_proc = lambda {|date_time| first_day_of_year(date_time)}
            when :monthly
              @cycle_advance_proc = lambda {|date_time| first_day_of_month(advance_month(date_time))}
              @current_proc = lambda {|date_time| same_month?(current, date_time)}
              @first_day_proc = lambda {|date_time| first_day_of_month(date_time)}
            when :weekly
              @cycle_advance_proc = lambda {|date_time| first_day_of_week(rrule.wkst_day, advance_week(date_time))}
              @current_proc = lambda {|date_time| same_week?(rrule.wkst_day, current, date_time)}
              @first_day_proc = lambda {|date_time| first_day_of_week(rrule.wkst_day, date_time)}
            else
              raise "Invalid recurrence rule, byday needs to be scoped by month, week or year"
            end
          end

          def self.for_rrule(rrule)
            list = rrule.by_rule_list(:byday)
            if list
              sub_cycle_incrementer = OccurrenceIncrementer::DailyIncrementer.for_rrule(rrule)
              new(rrule, list, rrule.by_rule_list(:bymonthday), rrule.by_rule_list(:byyearday), sub_cycle_incrementer)
            else
              OccurrenceIncrementer::ByYeardayIncrementer.for_rrule(rrule)
            end
          end
          
          def unneeded?(candidate)
            false
          end

          def daily_incrementer?
            true
          end

          def start_of_cycle(date_time)
            @first_day_proc.call(date_time)
          end

          def occurrences_for(date_time)
            first_day = start_of_cycle(date_time)
            result = list.map {|recurring_day| recurring_day.matches_for(first_day)}.flatten.uniq.sort
            if @monthday_filters
              result = result.select {|occurrence| @monthday_filters.any? {|recurring_day| recurring_day.include?(occurrence)}}
            end
            if @yearday_filters
              result = result.select {|occurrence| @yearday_filters.any? {|recurring_day| recurring_day.include?(occurrence)}}
            end
            result
          end

          def candidate_acceptable?(candidate)
            list.any? {|recurring_day| recurring_day.include?(candidate)}
          end

          def varying_time_attribute
            :day
          end

          def advance_cycle(date_time)
            @cycle_advance_proc.call(date_time)
          end

          def end_of_occurrence(date_time)
            date_time.end_of_day
          end
        end
      end
    end
  end
end