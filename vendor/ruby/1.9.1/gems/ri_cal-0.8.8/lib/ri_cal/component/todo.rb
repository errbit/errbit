module RiCal
  class Component
    #- ©2009 Rick DeNatale
    #- All rights reserved. Refer to the file README.txt for the license
    #
    # A Todo (VTODO) calendar component groups properties describing a to-do
    # Todos may have multiple occurrences
    #
    # Todos may also contain one or more ALARM subcomponents
    # to see the property accessing methods for this class see the RiCal::Properties::Todo module
    # to see the methods for enumerating occurrences of recurring to-dos see the RiCal::OccurrenceEnumerator module
    class Todo < Component
      include Properties::Todo
      include OccurrenceEnumerator

      def self.entity_name #:nodoc:
        "VTODO"
      end

      def subcomponent_class #:nodoc:
        {:alarm => Alarm }
      end
      
      # Return a date_time representing the time at which the todo should start
      def start_time
        dtstart_property ? dtstart.to_datetime : nil
      end
      
      # Return a date_time representing the time at which the todo is due
      def finish_time
        if due
          due_property.to_finish_time
        elsif duration_property && dtstart_property
          (dtstart_property + duration_property).to_finish_time
        else
          nil
        end
      end
      
    end
  end
end
