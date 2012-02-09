module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      module EnumerationSupportMethods # :nodoc:

        # if the recurrence rule has a bysetpos part we need to search starting with the
        # first time in the frequency period containing the start time specified by DTSTART
        def adjust_start(start_time) # :nodoc:
          if by_list[:bysetpos]
            case freq
            when "SECONDLY"
              start_time
            when "MINUTELY"
              start_time.change(:seconds => 0)
            when "HOURLY"
              start_time.change(
              :minutes => 0,
              :seconds => start_time.sec
              )
            when "DAILY"
              start_time.change(
              :hour => 0,
              :minutes => start_time.min,
              :seconds => start_time.sec
              )
            when "WEEKLY"
              start_of_week(time)
            when "MONTHLY"
              start_time.change(
              :day => 1,
              :hour => start_time.hour,
              :minutes => start_time.min,
              :seconds => start_time.sec
              )
            when "YEARLY"
              start_time.change(
              :month => 1,
              :day => start_time.day,
              :hour => start_time.hour,
              :minutes => start_time.min,
              :seconds => start_time.sec
              )
            end
          else
            start_time
          end
        end

        def enumerator(component) # :nodoc:
          Enumerator.for(self, component, by_list[:bysetpos])
        end

        def exhausted?(count, time) # :nodoc:
          (@count && count > @count) || (@until && (time > @until))
        end

        def in_same_set?(time1, time2) # :nodoc:
          case freq
          when "SECONDLY"
            [time1.year, time1.month, time1.day, time1.hour, time1.min, time1.sec] ==
            [time2.year, time2.month, time2.day, time2.hour, time2.min, time2.sec]
          when "MINUTELY"
            [time1.year, time1.month, time1.day, time1.hour, time1.min] ==
            [time2.year, time2.month, time2.day, time2.hour, time2.min]
          when "HOURLY"
            [time1.year, time1.month, time1.day, time1.hour] ==
            [time2.year, time2.month, time2.day, time2.hour]
          when "DAILY"
            [time1.year, time1.month, time1.day] ==
            [time2.year, time2.month, time2.day]
          when "WEEKLY"
            sow1 = start_of_week(time1)
            sow2 = start_of_week(time2)
            [sow1.year, sow1.month, sow1.day] ==
            [sow2.year, sow2.month, sow2.day]
          when "MONTHLY"
            [time1.year, time1.month] ==
            [time2.year, time2.month]
          when "YEARLY"
            time1.year == time2.year
          end
        end

         def by_rule_list(which) # :nodoc:
          if @by_list
            @by_list[which]
          else
            nil
          end
        end

        def incrementer_from_start_time(start_time)
          RecurrenceRule::OccurrenceIncrementer.from_rrule(self, start_time)
        end
      end
    end
  end
end