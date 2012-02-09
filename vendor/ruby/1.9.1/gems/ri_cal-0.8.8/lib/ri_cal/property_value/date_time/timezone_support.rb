module RiCal
  class PropertyValue
    class DateTime
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      # Time zone related methods for DateTime
      module TimezoneSupport
        # Return the timezone id of the receiver, or nil if it is a floating time
        def tzid
          @tzid  == :floating ? nil : @tzid
        end

        def tzid=(timezone_id) #:nodoc:
          timezone_id = default_tzid if timezone_id == :default
          @tzid = timezone_id
          reset_cached_values
        end

        def reset_cached_values #:nodoc:
          @timezone = @utc = @rational_tz_offset = nil
        end

        def find_timezone #:nodoc:
          if @tzid == :floating
            FloatingTimezone
          else
            timezone_finder.find_timezone(@tzid)
          end
        end

        def timezone #:nodoc:
          @timezone ||= find_timezone
        end

        # Determine if the receiver has a local time zone, i.e. it is not a floating time or a UTC time
        def has_local_timezone?
          tzid && tzid.upcase != "UTC"
        end

        # Return the receiver if it has a floating time zone already,
        # otherwise return a DATETIME property with the same time as the receiver but with a floating time zone
        def with_floating_timezone
          if @tzid == nil
            self
          else
            @date_time_value.with_floating_timezone.to_ri_cal_date_time_value
          end
        end

        # Returns a instance that represents the time in UTC.
        def utc
          if has_local_timezone?
            @utc ||= timezone.local_to_utc(self)
          else  # Already local or a floating time
            self
          end
        end

        def rational_tz_offset #:nodoc:
          if has_local_timezone?
            @rational_tz_offset ||= timezone.rational_utc_offset(@date_time_value.to_datetime)
          else
            @rational_tz_offset ||= RiCal.RationalOffset[0]
          end
        end

        # Predicate indicating whether or not the instance represents a ZULU time
        def utc?
          tzid == "UTC"
        end

        # Predicate indicating whether or not the instance represents a floating time
        def floating?
          tzid.nil?
        end

        def has_valid_tzinfo_tzid? #:nodoc:
          if tzid && tzid != :floating
            TZInfo::Timezone.get(tzid) rescue false
          else
            false
          end
        end

        # Returns the simultaneous time in the specified zone.
        def in_time_zone(new_zone)
          new_zone = timezone_finder.find_timezone(new_zone)
          return self if tzid == new_zone.identifier
          if has_local_timezone?
            new_zone.utc_to_local(utc)
          elsif utc?
            new_zone.utc_to_local(self)
          else # Floating time
            DateTime.new(timezone_finder, :value => @date_time_value, :tzid => new_zone.identifier)
          end
        end
      end
    end
  end
end