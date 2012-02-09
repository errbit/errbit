module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:

        # A FrequenceIncrementer represents the xxxLY and FREQ parts of a recurrence rule
        # A FrequenceIncrementer has a single occurrence within each cycle.
        class FrequencyIncrementer < OccurrenceIncrementer #:nodoc:
          attr_accessor :interval, :outer_occurrence, :skip_increment

          alias_method :cycle_start, :current_occurrence

          def initialize(rrule, sub_cycle_incrementer)
            super(rrule, sub_cycle_incrementer)
            self.interval = rrule.interval
          end

          def self.conditional_incrementer(rrule, freq_str, sub_cycle_class)
            sub_cycle_incrementer = sub_cycle_class.for_rrule(rrule)
            if rrule.freq == freq_str
              new(rrule, sub_cycle_incrementer)
            else
              sub_cycle_incrementer
            end
          end

          def multiplier
            1
          end

          def step(occurrence)
            occurrence.advance(advance_what => (interval * multiplier))
          end
          
          def sub_cycle_incrementer
            if @sub_cycle_incrementer.unneeded?(current_occurrence || @previous_occurrence)
              NullSubCycleIncrementer
            else
              super
            end
          end

          def first_within_outer_cycle(previous_occurrence, outer_cycle_range)
            if outer_range
              first_occurrence = outer_cycle_range.first
            else
              first_occurrence = step(previous_occurrence)
            end
            self.outer_range = outer_cycle_range
            sub_cycle_incrementer.first_within_outer_cycle(previous_occurrence, update_cycle_range(first_occurrence))
          end

          # Advance to the next occurrence, if the result is within the current cycles of all outer incrementers
          def next_cycle(previous_occurrence)
            @sub_cycle_dtstart = previous_occurrence
            if current_occurrence
              candidate = sub_cycle_incrementer.cycle_adjust(step(current_occurrence))
            else
              candidate = step(previous_occurrence)
            end
            if outermost?
              sub_occurrence = sub_cycle_incrementer.first_within_outer_cycle(previous_occurrence, update_cycle_range(candidate))
              until sub_occurrence
                candidate = sub_cycle_incrementer.cycle_adjust(step(candidate))
                sub_occurrence = sub_cycle_incrementer.first_within_outer_cycle(previous_occurrence, update_cycle_range(candidate))
              end
              sub_occurrence
            elsif in_outer_cycle?(candidate)
              sub_cycle_incrementer.first_within_outer_cycle(previous_occurrence, update_cycle_range(candidate))
            else
              nil
            end
          end
        end
      end
    end
  end
end
