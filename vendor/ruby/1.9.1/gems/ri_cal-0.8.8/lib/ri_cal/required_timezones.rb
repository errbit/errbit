module RiCal
  #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
  #
  # RequireTimezones collects the timezones used by a given calendar component or set of calendar components
  # For each timezone we collect it's id, and the earliest and latest times which reference the zone
  class RequiredTimezones #:nodoc:
    
    
    # A required timezone represents a single timezone and the earliest and latest times which reference it.
    class RequiredTimezone #:nodoc:
      
      attr_reader :first_time, :last_time, :timezone
      
      def initialize(tzid)
        @timezone = RiCal::Component::TZInfoTimezone.new(TZInfo::Timezone.get(tzid))
      end
      
      def tzid
        @timezone.identifier
      end
      
      def add_datetime(date_time)
        if @first_time 
          @first_time = date_time if date_time < @first_time
        else
          @first_time = date_time
        end
        if @last_time 
          @last_time = date_time if date_time > @last_time
        else
          @last_time = date_time
        end
      end
    end
    
    def required_timezones
      @required_zones ||= {}
    end
    
    def required_zones
      required_timezones.values
    end
    
    def export_to(export_stream)
      required_zones.each do |z|
        tzinfo_timezone =z.timezone
        tzinfo_timezone.export_local_to(export_stream, z.first_time, z.last_time)
      end
    end
    
    def add_datetime(date_time, tzid)
      (required_timezones[tzid] ||= RequiredTimezone.new(tzid)).add_datetime(date_time)
    end
  end
end