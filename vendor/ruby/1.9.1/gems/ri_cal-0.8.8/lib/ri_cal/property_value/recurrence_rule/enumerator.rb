module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class Enumerator # :nodoc:
        # base_time gets changed everytime the time is updated by the recurrence rule's frequency
        attr_accessor :start_time, :duration, :next_time, :recurrence_rule, :base_time
        def initialize(recurrence_rule, component, setpos_list)
          self.recurrence_rule = recurrence_rule
          self.start_time = component.default_start_time
          self.duration = component.default_duration
          self.next_time = recurrence_rule.adjust_start(self.start_time)
          self.base_time = next_time
          @bounded = recurrence_rule.bounded?
          @count = 0
          @setpos_list = setpos_list
          @setpos = 1
          @next_occurrence_count = 0
          @incrementer = recurrence_rule.incrementer_from_start_time(start_time)
        end

        def self.for(recurrence_rule, component, setpos_list) # :nodoc:
          if !setpos_list || setpos_list.all? {|setpos| setpos > 1}
            self.new(recurrence_rule, component, setpos_list)
          else
            NegativeSetposEnumerator.new(recurrence_rule, component, setpos_list)
          end
        end

         def empty?
          false
        end

        def bounded?
          @bounded
        end

        def result_occurrence_period(date_time_value)
          RiCal::OccurrencePeriod.new(date_time_value, nil)
        end

        def result_passes_setpos_filter?(result)
          result_setpos = @setpos
          if recurrence_rule.in_same_set?(result, next_time)
            @setpos += 1
          else
            @setpos = 1
          end
          if (result == start_time) || (result > start_time && @setpos_list.include?(result_setpos))
            return true
          else
            return false
          end
        end

        def result_passes_filters?(result)
          if @setpos_list
            result_passes_setpos_filter?(result)
          else
            result >= start_time
          end
        end

        def next_occurrence
          while true
            @next_occurrence_count += 1
            result = next_time
            self.next_time = @incrementer.next_time(result)
            if result_passes_filters?(result)
              @count += 1
              return recurrence_rule.exhausted?(@count, result) ? nil : result_occurrence_period(result)
            end
          end
        end
      end
    end
  end
end
