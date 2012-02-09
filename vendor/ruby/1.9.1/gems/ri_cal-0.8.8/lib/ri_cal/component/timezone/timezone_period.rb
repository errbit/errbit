module RiCal
  class Component
    class Timezone
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      # A TimezonePeriod is a component of a timezone representing a period during which a particular offset from UTC is
      # in effect.
      #
      # to see the property accessing methods for this class see the RiCal::Properties::TimezonePeriod module
      class TimezonePeriod < Component
        include Properties::TimezonePeriod

        include OccurrenceEnumerator

        def occurrence_cache #:nodoc:
          @occurrence_cache ||= []
        end

        def zone_identifier #:nodoc:
          tzname.first
        end

        def dtend #:nodoc:
          nil
        end

        def exdate_property #:nodoc:
          nil
        end

        def utc_total_offset #:nodoc:
          tzoffsetto_property.to_seconds
        end

        def exrule_property #:nodoc:
          nil
        end

        def last_before_utc(utc_time) #:nodoc:
          last_before_local(utc_time + tzoffsetfrom_property)
        end

        def fill_cache(local_time)
          if occurrence_cache.empty? || occurrence_cache.last.dtstart_property <= local_time
            while true
              occurrence = enumeration_instance.next_occurrence
              break unless occurrence
              occurrence = recurrence(occurrence)
              occurrence_cache << occurrence
              break if occurrence.dtstart_property > local_time
            end
          end
        end

        def last_before_local(local_time) #:nodoc:
          if recurs?
            fill_cache(local_time)
            cand_occurrence = nil
            occurrence_cache.each do |occurrence|
              return cand_occurrence if occurrence.dtstart_property > local_time
              cand_occurrence = occurrence
            end
            return cand_occurrence
          else
            return self
          end
        end

         def enumeration_instance
          @enumeration_instance ||= super
        end
      end
    end
  end
end

