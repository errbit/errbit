module RiCal
  class PropertyValue
    class DateTime
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      # Methods for DateTime which support getting values at different point in time.
      module TimeMachine

        def advance(options) # :nodoc:
          PropertyValue::DateTime.new(timezone_finder,
          :value => @date_time_value.advance(options),
          :tzid => @tzid,
          :params =>(params ? params.dup : nil)
          )
        end

        def change(options) # :nodoc:
          PropertyValue::DateTime.new(timezone_finder,
          :value => @date_time_value.change(options),
          :tzid => @tzid,
          :params => (params ? params.dup : nil)
          )
        end

        def change_sec(new_sec) #:nodoc:
          change(:sec => new_sec)
        end

        def change_min(new_min) #:nodoc:
          change(:min => new_min)
        end

        def change_hour(new_hour) #:nodoc:
          change(:hour => new_hour)
        end

        def change_day(new_day) #:nodoc:
          change(:day => new_day)
        end

        def change_month(new_month) #:nodoc:
          change(:month => new_month)
        end

        def change_year(new_year) #:nodoc:
          change(:year => new_year)
        end

        # Return a DATE-TIME property representing the receiver on a different day (if necessary) so that
        # the result is within the 7 days starting with date
        def in_week_starting?(date)
          wkst_jd = date.jd
          @date_time_value.jd.between?(wkst_jd, wkst_jd + 6)
        end

        # Return a DATE-TIME property representing the receiver on a different day (if necessary) so that
        # the result is the first day of the ISO week starting on the wkst day containing the receiver.
        def at_start_of_week_with_wkst(wkst)
          date = @date_time_value.start_of_week_with_wkst(wkst)
          change(:year => date.year, :month => date.month, :day => date.day)
        end
        # Return a DATE_TIME value representing the first second of the minute containing the receiver
        def start_of_minute
          change(:sec => 0)
        end

        # Return a DATE_TIME value representing the last second of the minute containing the receiver
        def end_of_minute
          change(:sec => 59)
        end

        # Return a DATE_TIME value representing the first second of the hour containing the receiver
        def start_of_hour
          change(:min => 0, :sec => 0)
        end

        # Return a DATE_TIME value representing the last second of the hour containing the receiver
        def end_of_hour
          change(:min => 59, :sec => 59)
        end

        # Return a DATE_TIME value representing the first second of the day containing the receiver
        def start_of_day
          change(:hour => 0, :min => 0, :sec => 0)
        end

        # Return a DATE_TIME value representing the last second of the day containing the receiver
        def end_of_day
          change(:hour => 23, :min => 59, :sec => 59)
        end

        # Return a Ruby Date representing the first day of the ISO week starting with wkst containing the receiver
        def start_of_week_with_wkst(wkst)
          @date_time_value.start_of_week_with_wkst(wkst)
        end

        # Return a DATE_TIME value representing the last second of the ISO week starting with wkst containing the receiver
        def end_of_week_with_wkst(wkst)
          date = at_start_of_week_with_wkst(wkst).advance(:days => 6).end_of_day
        end

        # Return a DATE_TIME value representing the first second of the month containing the receiver
        def start_of_month
          change(:day => 1, :hour => 0, :min => 0, :sec => 0)
        end

        # Return a DATE_TIME value representing the last second of the month containing the receiver
        def end_of_month
          change(:day => days_in_month, :hour => 23, :min => 59, :sec => 59)
        end

        # Return a DATE_TIME value representing the first second of the month containing the receiver
        def start_of_year
          change(:month => 1, :day => 1, :hour => 0, :min => 0, :sec => 0)
        end

        # Return a DATE_TIME value representing the last second of the month containing the receiver
        def end_of_year
          change(:month => 12, :day => 31, :hour => 23, :min => 59, :sec => 59)
        end

        # Return a DATE_TIME value representing the same time on the first day of the ISO year with weeks
        # starting on wkst containing the receiver
        def at_start_of_iso_year(wkst)
          start_of_year = @date_time_value.iso_year_start(wkst)
          change(:year => start_of_year.year, :month => start_of_year.month, :day => start_of_year.day)
        end

        # Return a DATE_TIME value representing the same time on the last day of the ISO year with weeks
        # starting on wkst containing the receiver
        def at_end_of_iso_year(wkst)
          num_weeks = @date_time_value.iso_weeks_in_year(wkst)
          at_start_of_iso_year(wkst).advance(:weeks => (num_weeks - 1), :days => 6)
        end

        # Return a DATE_TIME value representing the same time on the first day of the ISO year with weeks
        # starting on wkst after the ISO year containing the receiver
        def at_start_of_next_iso_year(wkst)
          num_weeks = @date_time_value.iso_weeks_in_year(wkst)
          at_start_of_iso_year(wkst).advance(:weeks => num_weeks)
        end

        # Return a DATE_TIME value representing the last second of the last day of the ISO year with weeks
        # starting on wkst containing the receiver
        def end_of_iso_year(wkst)
          at_end_of_iso_year(wkst).end_of_day
        end

        # Return a DATE-TIME representing the same time, on the same day of the month in month.
        # If the month of the receiver has more days than the target month the last day of the target month
        # will be used.
        def in_month(month)
          first = change(:day => 1, :month => month)
          first.change(:day => [first.days_in_month, day].min)
        end
      end
    end
  end
end