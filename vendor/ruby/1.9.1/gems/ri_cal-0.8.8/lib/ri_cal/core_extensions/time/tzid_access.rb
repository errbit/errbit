module RiCal
  module CoreExtensions #:nodoc:
    module Time #:nodoc:
      #- ©2009 Rick DeNatale
      #- All rights reserved. Refer to the file README.txt for the license
      #
      # Provides a tzid attribute for ::Time and ::DateTime
      module TzidAccess
        # The tzid attribute is used by RiCal, it should be a valid timezone identifier within a calendar,
        # :floating to indicate a floating time, or nil to use the default timezone in effect
        #
        # See PropertyValue::DateTime#default_tzid= and Component::Calendar#tzid=
        attr_accessor :tzid

        # Convenience method, sets the tzid and returns the receiver
        def set_tzid(time_zone_identifier)
          self.tzid = time_zone_identifier
          self
        end

        # Predicate indicating whether or not the instance represents a floating time
        def has_floating_timezone?
          tzid == :floating
        end

      end
    end
  end

  module TimeWithZoneExtension #:nodoc:
    def tzid
      utc? ? "UTC" : time_zone.tzinfo.identifier
    end

    # Predicate indicating whether or not the instance represents a floating time
    def has_floating_timezone?
      false
    end

    def to_ri_cal_date_time_value(timezone_finder=nil)
      ::RiCal::PropertyValue::DateTime.new(timezone_finder, :params => {"TZID" => tzid}, :value => strftime("%Y%m%dT%H%M%S"))
    end
    alias_method :to_ri_cal_date_or_date_time_value, :to_ri_cal_date_time_value
    alias_method :to_ri_cal_occurrence_list_value, :to_ri_cal_date_time_value
  end
end

if RiCal::TimeWithZone
  RiCal::TimeWithZone.class_eval {include RiCal::TimeWithZoneExtension}
end