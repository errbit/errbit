module RiCal
  class Component
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    #  A Journal (VJOURNAL) calendar component groups properties describing a journal entry.
    #  Journals may have multiple occurrences
    # to see the property accessing methods for this class see the RiCal::Properties::Journal module
    # to see the methods for enumerating occurrences of recurring journals see the RiCal::OccurrenceEnumerator module
    class Journal < Component
      include RiCal::Properties::Journal
      include RiCal::OccurrenceEnumerator

      def self.entity_name #:nodoc:
        "VJOURNAL"
      end
      
      # Return a date_time representing the time at which the event starts
      def start_time
        dtstart.to_datetime
      end
      
      # Journals take up no calendar time, so the finish time is always the same as the start_time
      alias_method :finish_time, :start_time
      
    end
  end
end
