module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      # Instances of RecurringDay are used to represent values in BYDAY recurrence rule parts
      #
      class RecurringDay # :nodoc: 
        
        attr_reader :wday, :index, :rrule

        DayNames = %w{SU MO TU WE TH FR SA} unless defined? DayNames
        day_nums = {}
        unless defined? DayNums
          DayNames.each_with_index { |name, i| day_nums[name] = i }
          DayNums = day_nums
        end

        attr_reader :source, :scope
        def initialize(source, rrule, scope = :monthly)
          @source = source
          @rrule = rrule
          @scope = scope
          wd_match = source.match(/([+-]?\d*)(SU|MO|TU|WE|TH|FR|SA)/)
          if wd_match
            @day, @ordinal = wd_match[2], wd_match[1]
            @wday = DayNums[@day]
            @index = (@ordinal == "") ? nil : @ordinal.to_i
          end
        end

        def valid?
          !@day.nil?
        end

        def ==(another)
          self.class === another && to_a = another.to_a
        end

        def to_a
          [@day, @ordinal]
        end
        
        # return a list id for a given time to allow the enumerator to cache lists
        def list_id(time)
          case @scope
          when :yearly
            time.year
          when :monthly
            (time.year * 100) + time.month
          when :weekly
            time.at_start_of_week_with_wkst(rrule.wkst_day).jd
          end
        end
        
        # return a list of times which match the time parameter within the scope of the RecurringDay
        def matches_for(time)
          case @scope
          when :yearly
            yearly_matches_for(time)
          when :monthly
            monthly_matches_for(time)
          when :weekly
            weekly_matches_for(time)
          else
            walkback = caller.grep(/recurrence/i)
            raise "Logic error!#{@scope.inspect}\n  #{walkback.join("\n  ")}"
          end         
        end
        
        def yearly_matches_for(time)
          if @ordinal == ""
            t = time.nth_wday_in_year(1, wday)
            result = []
            year = time.year
            while t.year == year
              result << t
              t = t.advance(:week => 1)
            end
            result
          else
            [time.nth_wday_in_year(@ordinal.to_i, wday)]
          end
        end
        
        def monthly_matches_for(time)
          if @ordinal == ""
            t = time.nth_wday_in_month(1, wday)
            result = []
            month = time.month
            while t.month == month
              result << t
              t = t.advance(:days => 7)
            end
            result
          else
            result = [time.nth_wday_in_month(index, wday)]
            result
          end
        end

        def weekly_matches_for(time)
          date = time.start_of_week_with_wkst(rrule.wkst_day)
          date += 1 while date.wday != wday
          [time.change(:year => date.year, :month => date.month, :day => date.day)]
        end

        def to_s
          "#{@ordinal}#{@day}"
        end
        
        def ordinal_match(date_or_time)
          if @ordinal == "" || @scope == :weekly
            true
          else
            if @scope == :yearly
              date_or_time.nth_wday_in_year?(index, wday) 
            else
              date_or_time.nth_wday_in_month?(index, wday)
            end
          end
        end

        # Determine if a particular date, time, or date_time is included in the recurrence
        def include?(date_or_time)
          date_or_time.wday == wday && ordinal_match(date_or_time)
        end
      end
    end
  end
end