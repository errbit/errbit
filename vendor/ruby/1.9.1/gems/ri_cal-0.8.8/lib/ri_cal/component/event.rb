module RiCal
  class Component
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    # An Event (VEVENT) calendar component groups properties describing a scheduled event.
    # Events may have multiple occurrences
    #
    # Events may also contain one or more ALARM subcomponents
    #
    # to see the property accessing methods for this class see the RiCal::Properties::Event module
    # to see the methods for enumerating occurrences of recurring events see the RiCal::OccurrenceEnumerator module
    class Event < Component
      include OccurrenceEnumerator

      include RiCal::Properties::Event

      def subcomponent_class #:nodoc:
        {:alarm => Alarm }
      end

      def self.entity_name #:nodoc:
        "VEVENT"
      end
      
      # Return a date_time representing the time at which the event starts
      def start_time
        dtstart_property ? dtstart.to_datetime : nil
      end
      
      # Return a date_time_property representing the time at which the event ends
      def finish_property
        if dtend_property
          dtend_property
        elsif duration_property
          (dtstart_property + duration_property)
        else
          dtstart_property
        end
      end

      # Return a date_time representing the time at which the event starts
      def finish_time
        prop = finish_property
        prop ? prop.to_finish_time : nil
      end
      
      def zulu_occurrence_range_start_time
        dtstart_property ? dtstart_property.to_zulu_occurrence_range_start_time : nil
       end
      
      def zulu_occurrence_range_finish_time
        prop = finish_property
        prop ? prop.to_zulu_occurrence_range_finish_time : nil
      end
      
    end
  end
end