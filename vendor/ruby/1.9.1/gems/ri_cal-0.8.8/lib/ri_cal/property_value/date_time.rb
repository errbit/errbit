require 'date'
module RiCal
  class PropertyValue
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    # RiCal::PropertyValue::CalAddress represents an icalendar CalAddress property value
    # which is defined in RFC 2445 section 4.3.5 pp 35-37
    class DateTime < PropertyValue

      Dir[File.dirname(__FILE__) + "/date_time/*.rb"].sort.each do |path|
        require path
      end

      include Comparable
      include AdditiveMethods
      include TimezoneSupport
      include TimeMachine

      def self.or_date(parent, line) # :nodoc:
        if /T/.match(line[:value] || "")
          new(parent, line)
        else
          PropertyValue::Date.new(parent, line)
        end
      end
      
      def self.valid_string?(string) #:nodoc:
        string =~ /^\d{8}T\d{6}Z?$/
      end

      def self.default_tzid # :nodoc:
        @default_tzid ||= "UTC"
      end

      def self.params_for_tzid(tzid) #:nodoc:
        if tzid == :floating
          {}
        else
          {'TZID' => tzid}
        end
      end

      # Set the default tzid to be used when instantiating an instance from a ruby object
      # see RiCal::PropertyValue::DateTime.from_time
      #
      # The parameter tzid is a string value to be used for the default tzid, a value of :floating will cause
      # values with NO timezone to be produced, which will be interpreted by iCalendar as floating times
      # i.e. they are interpreted in the timezone of each client. Floating times are typically used
      # to represent events which are 'repeated' in the various time zones, like the first hour of the year.
      def self.default_tzid=(tzid)
        @default_tzid = tzid
      end

      def self.default_tzid_hash # :nodoc:
        if default_tzid.to_s == 'none'
          {}
        else
          {'TZID' => default_tzid}
        end
      end
      
      def inspect # :nodoc:
        "#{@date_time_value}:#{tzid}"
      end

      # Returns the value of the receiver as an RFC 2445 iCalendar string
      def value
        if @date_time_value
          "#{@date_time_value.ical_str}#{tzid == "UTC" ? "Z" : ""}"
        else
          nil
        end
      end
      
      def to_ri_cal_zulu_date_time
        ZuluDateTime.new(nil, :value => self.utc.fast_date_tme)
      end
      
      def fast_date_tme # :nodoc:
        @date_time_value
      end

      # Set the value of the property to val
      #
      # val may be either:
      #
      # * A string which can be parsed as a DateTime
      # * A Time instance
      # * A Date instance
      # * A DateTime instance
      def value=(val) # :nodoc:
        case val
        when nil
          @date_time_value = nil
        when String
          @date_time_value = FastDateTime.from_date_time(::DateTime.parse(val))
          if val =~/Z/
            self.tzid = 'UTC'
          else
            @tzid ||= :floating
          end
        when FastDateTime
          @date_time_value = val
        when ::DateTime
          @date_time_value = FastDateTime.from_date_time(val)
        when ::Date, ::Time
          @date_time_value = FastDateTime.from_date_time(::DateTime.parse(val.to_s))
        end
        reset_cached_values
      end
      
      # Extract the time and timezone identifier from an object used to set the value of a DATETIME property.
      #
      # If the object is a string it should be of the form [TZID=identifier:]
      #
      # Otherwise determine if the object acts like an activesupport enhanced time, and extract its timezone
      # idenfifier if it has one.
      #
      def self.time_and_parameters(object)
        parameters = {}
        if ::String === object
          object, parameters = self.time_and_parameters_from_string(object)
        else
          identifier = object.tzid rescue nil
          parameters["TZID"] = identifier if identifier
        end
        [object, parameters]
      end


      def self.convert(timezone_finder, ruby_object) # :nodoc:
          ruby_object.to_ri_cal_date_or_date_time_value(timezone_finder)
      end

      def self.from_string(string) # :nodoc:
        if string.match(/Z$/)
          new(nil, :value => string, :tzid => 'UTC')
        else
          new(nil, :value => string)
        end
      end

      def for_parent(parent) #:nodoc:
        if timezone_finder.nil?
          @timezone_finder = parent
          self
        elsif parent == timezone_finder
          self
        else
          DateTime.new(parent, :value => @date_time_value, :params => params, :tzid => tzid)
        end
      end

      def visible_params # :nodoc:
        result = {"VALUE" => "DATE-TIME"}.merge(params)
        if has_local_timezone?
          result['TZID'] = tzid
        else
          result.delete('TZID')
        end
        result
      end

      def params=(value) #:nodoc:
        @params = value.dup
        if params_timezone = @params['TZID']
          self.tzid =  @params['TZID']
        end
      end
      
      # Return a Hash representing this properties parameters
      def params
        result = @params.dup
        case tzid
        when :floating, nil, "UTC"
          result.delete('TZID')
        else
          result['TZID'] = tzid
        end
        result
      end

      # Compare the receiver with another object which must respond to the to_datetime message
      # The comparison is done using the Ruby DateTime representations of the two objects
      def <=>(other)
       other.cmp_fast_date_time_value(@date_time_value)
      end
      
      def cmp_fast_date_time_value(other)
        other <=> @date_time_value
      end

      # Determine if the receiver and other are in the same month
      def in_same_month_as?(other)
        [other.year, other.month] == [year, month]
      end

      def with_date_time_value(date_time_value)
        PropertyValue::DateTime.new(
          timezone_finder,
          :value => date_time_value,
          :params => (params),
          :tzid => tzid
        )
      end
      
      def nth_wday_in_month(n, which_wday) #:nodoc:
        with_date_time_value(@date_time_value.nth_wday_in_month(n, which_wday))
      end

      def nth_wday_in_year(n, which_wday) #:nodoc:
        with_date_time_value(@date_time_value.nth_wday_in_year(n, which_wday))
      end

      def self.civil(year, month, day, hour, min, sec, offset, start, params) #:nodoc:
        PropertyValue::DateTime.new(
           :value => ::DateTime.civil(year, month, day, hour, min, sec, offset, start),
           :params =>(params ? params.dup : nil)
        )
      end

      # Return the number of days in the month containing the receiver
      def days_in_month
        @date_time_value.days_in_month
      end

      # Determine if the receiver and another object are equivalent RiCal::PropertyValue::DateTime instances
      def ==(other)
        if self.class === other
          self.value == other.value && self.visible_params == other.visible_params && self.tzid == other.tzid
        else
          super
        end
      end

      # TODO: consider if this should be a period rather than a hash
      def occurrence_period(default_duration) # :nodoc:
        RiCal::OccurrencePeriod.new(self, (default_duration ? self + default_duration : nil))
      end

      # Return the year (including the century)
      def year
        @date_time_value.year
      end

      # Return the month of the year (1..12)
      def month
        @date_time_value.month
      end

      # Return the day of the month
      def day
        @date_time_value.day
      end

      alias_method :mday, :day

      # Return the day of the week
      def wday
        @date_time_value.wday
      end

      # Return the hour
      def hour
        @date_time_value.hour
      end

      # Return the minute
      def min
        @date_time_value.min
      end

       # Return the second
      def sec
        @date_time_value.sec
      end


      # Return an RiCal::PropertyValue::DateTime representing the receiver.
      def to_ri_cal_date_time_value(timezone=nil)
        for_parent(timezone)
      end

      def iso_year_and_week_one_start(wkst) #:nodoc:
        @date_time_value.iso_year_and_week_one_start(wkst)
      end

      def iso_weeks_in_year(wkst) #:nodoc:
        @date_time_value.iso_weeks_in_year(wkst) #:nodoc:
      end

      # Return the "Natural' property value for the receover, in this case the receiver itself."
      def to_ri_cal_date_or_date_time_value(timezone_finder = nil) #:nodoc:
        self.for_parent(timezone_finder)
      end
      
      # Return a Date property for this DateTime
      def to_ri_cal_date_value(timezone_finder=nil)
        PropertyValue::Date.new(timezone_finder, :value => @date_time_value.ical_date_str)
      end

      # Return the Ruby DateTime representation of the receiver
      def to_datetime #:nodoc:
        @date_time_value.to_datetime
      end

      # Returns a ruby DateTime object representing the receiver.
      def ruby_value
        if has_valid_tzinfo_tzid? && RiCal::TimeWithZone && tz_info_source?
          RiCal::TimeWithZone.new(utc.to_datetime, ::Time.__send__(:get_zone, @tzid))
        else
          ::DateTime.civil(year, month, day, hour, min, sec, rational_tz_offset).set_tzid(@tzid)
        end
      end

      alias_method :to_ri_cal_ruby_value, :to_datetime
      alias_method :to_finish_time, :ruby_value
      
      def to_zulu_time
        utc.to_datetime
      end
      
      # If a time is floating, then the utc of it's start time may actually be as early 
      # as 12 hours earlier if the occurrence is being viewed in a time zone just west
      # of the International Date Line
      def to_zulu_occurrence_range_start_time
        if floating?
          @date_time_value.advance(:hours => -12, :offset => 0).to_datetime
        else
          to_zulu_time
        end
      end
      
      
      # If a time is floating, then the utc of it's start time may actually be as early 
      # as 12 hours later if the occurrence is being viewed in a time zone just east
      # of the International Date Line
      def to_zulu_occurrence_range_finish_time
        if floating?
          utc.advance(:hours => 12).to_datetime
        else
          to_zulu_time
        end
      end
      
      def add_date_times_to(required_timezones) #:nodoc:
        required_timezones.add_datetime(self, tzid) if has_local_timezone?
      end
      
      def start_of_day?
        [hour, min, sec] == [0,0,0]
      end
      
      def for_occurrence(occurrence)
        occurrence.to_ri_cal_date_time_value(timezone_finder)
      end
    end
  end
end