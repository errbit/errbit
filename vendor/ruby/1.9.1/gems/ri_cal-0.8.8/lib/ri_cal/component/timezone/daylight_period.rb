module RiCal
  class Component
    class Timezone
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      # A DaylightPeriod is a TimezonePeriod during which daylight saving time *is* in effect
      class DaylightPeriod < TimezonePeriod #:nodoc: all

        def self.entity_name #:nodoc:
          "DAYLIGHT"
        end

        def dst?
          true
        end

        def swallows_local?(local, std_candidate)
          ([local.year, local.month, local.day] == [dtstart.year,dtstart.month, dtstart.day]) && 
             local >= dtstart_property &&
             local.advance(:seconds => (std_candidate.utc_total_offset - utc_total_offset)) < dtstart_property
        end
      end
    end
  end
end