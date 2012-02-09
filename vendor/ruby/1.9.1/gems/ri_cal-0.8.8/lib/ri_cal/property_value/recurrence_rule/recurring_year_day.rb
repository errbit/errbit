module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class RecurringYearDay < NumberedSpan # :nodoc:

        def last
          366
        end

        def leap_year?(year)
          year % 4 == 0 && (year % 400 == 0 || year % 100 != 0)
        end 


        def length_of_year(year)
          leap_year?(year) ? 366 : 365
        end 
        
        # return a list id for a given time to allow the enumerator to cache lists
        def list_id(time)
          time.year
        end

        # return a list of times which match the time parameter within the scope of the RecurringDay
        def matches_for(time)
          [time.change(:month => 1, :day => 1).advance(:days => target_for(time)- 1)]
        end
        
        def target_date_time_for(date_time)
          matches_for(date_time)[0]
        end
        
        def fixed_day?
          @source > 0
        end

        def target_for(date_or_time)
          if fixed_day?
            @source
          else
            length_of_year(date_or_time.year) + @source + 1
          end
        end
        
        def include?(date_or_time)
          date_or_time.yday == target_for(date_or_time)
        end
      end
    end
  end
end