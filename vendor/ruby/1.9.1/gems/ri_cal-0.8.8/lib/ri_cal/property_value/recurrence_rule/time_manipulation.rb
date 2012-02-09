module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      module TimeManipulation #:nodoc:

        def advance_day(date_time)
          date_time.advance(:days => 1)
        end

        def first_hour_of_day(date_time)
          date_time.change(:hour => 0)
        end

        def advance_week(date_time)
          date_time.advance(:days => 7)
        end

        def first_day_of_week(wkst_day, date_time)
          date_time.at_start_of_week_with_wkst(wkst_day)
        end

        def advance_month(date_time)
          date_time.advance(:months => 1)
        end

        def first_day_of_month(date_time)
          date_time.change(:day => 1)
        end

        def advance_year(date_time)
          date_time.advance(:years => 1)
        end

        def first_day_of_year(date_time)
          date_time.change(:month => 1, :day => 1)
        end
      end
    end
  end
end