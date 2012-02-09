module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class RecurringNumberedWeek < NumberedSpan # :nodoc:
        def last
          53
        end
         
        def rule_wkst
          @rule && rule.wkst_day
        end
        
        def default_wkst
          rule_wkst || 1
        end
        
        def adjusted_iso_weeknum(date_or_time)
          if @source > 0
            @source
          else
            date_or_time.iso_weeks_in_year(wkst) + @source + 1
          end
        end
        
        def include?(date_or_time, wkst=default_wkst)
          date_or_time.iso_week_num(wkst) == adjusted_iso_weeknum(date_or_time)
        end
      end
    end
  end
end