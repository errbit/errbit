module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      # Instances of RecurringMonthDay represent BYMONTHDAY parts in recurrence rules
      class RecurringMonthDay < NumberedSpan # :nodoc:

        def last
          31
        end
        
        # return a list id for a given time to allow the enumerator to cache lists
        def list_id(time)
          time.month
        end
 
        # return a list of times which match the time parameter within the scope of the RecurringDay
        def matches_for(time)
          [time.change(:day => 1).advance(:days => target_for(time)- 1)]
        end
        
        # return a list id for a given time to allow the enumerator to cache lists
        def list_id(time)
          time.month
        end
 
        # return a list of times which match the time parameter within the scope of the RecurringDay
        def matches_for(time)
          [time.change(:day => 1).advance(:days => target_for(time)- 1)]
        end
        
        def target_date_time_for(date_time)
          matches_for(date_time)[0]
        end

        # return a list of times which match the time parameter within the scope of the RecurringDay
        def matches_for(time)
          [time.change(:day => 1).advance(:days => target_for(time)- 1)]
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
            date_or_time.days_in_month + @source + 1
          end
        end

        def include?(date_or_time)
          date_or_time.mday == target_for(date_or_time)
        end
      end
    end
  end
end