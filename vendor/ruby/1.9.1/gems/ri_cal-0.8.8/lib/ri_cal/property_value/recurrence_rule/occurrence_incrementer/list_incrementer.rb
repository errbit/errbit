module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      class OccurrenceIncrementer # :nodoc:

        # A ListIncrementer represents a byxxx part of a recurrence rule
        # It contains a list of simple values or recurring values
        # It keeps a collection of occurrences within a given range called a cycle
        # When the collection of occurrences is exhausted it is refreshed if there is no
        # outer incrementer, or if a new cycle would start in the current cycle of the outer incrementers.
        class ListIncrementer < OccurrenceIncrementer #:nodoc:
          attr_accessor :occurrences, :list, :outer_occurrence, :cycle_start

          def initialize(rrule, list, sub_cycle_incrementer)
            super(rrule, sub_cycle_incrementer)
            self.list = list
          end

          def self.conditional_incrementer(rrule, by_part, sub_cycle_class)
            sub_cycle_incrementer = sub_cycle_class.for_rrule(rrule)
            list = rrule.by_rule_list(by_part)
            if list
              new(rrule, list, sub_cycle_incrementer)
            else
              sub_cycle_incrementer
            end
          end

          # Advance to the next occurrence, if the result is within the current cycles of all outer incrementers
          def next_cycle(previous_occurrence)
            unless occurrences
              self.occurrences = occurrences_for(previous_occurrence)
            end
            candidate = next_candidate(previous_occurrence)
            if candidate
              sub_cycle_incrementer.first_within_outer_cycle(previous_occurrence, update_cycle_range(candidate))
            else
              nil
            end
          end
          
          def unneeded?(candidate)
            sub_cycle_incrementer.unneeded?(candidate) &&
            list.length == 1 && 
            candidate_acceptable?(candidate)
          end
          
          def candidate_acceptable?(candidate)
            list.any? {|value| candidate.send(varying_time_attribute) == value}
          end

          def first_within_outer_cycle(previous_occurrence, outer_range)
            self.outer_range = outer_range
            self.occurrences = occurrences_within(outer_range)
            occurrences.each { |occurrence|
              sub = sub_cycle_incrementer.first_within_outer_cycle(previous_occurrence, update_cycle_range(occurrence))
              return sub if sub && sub > previous_occurrence
            }
            nil
          end

          def next_candidate(date_time)
            candidate = next_in_list(date_time)
            if outermost?
              while candidate.nil?
                get_next_occurrences
                candidate = next_in_list(date_time)
              end
            end
            candidate
          end

          def next_in_list(date_time)
            occurrences.find {|occurrence| occurrence > date_time}
          end

          def get_next_occurrences
            adv_cycle = advance_cycle(start_of_cycle(occurrences.first))
            self.occurrences = occurrences_for(adv_cycle)
          end

          def cycle_adjust(date_time)
            sub_cycle_incrementer.cycle_adjust(start_of_cycle(date_time))
          end

          def occurrences_for(date_time)
            list.map {|value| date_time.change(varying_time_attribute => value)}
          end

          def occurrences_within(date_time_range)
            result = []
            date_time = date_time_range.first
            while date_time <= date_time_range.last
               result << occurrences_for(date_time)
               date_time = advance_cycle(date_time)
             end
             result.flatten
          end
        end
      end
    end
  end
end

