require 'date'
module RiCal
  class PropertyValue
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    # RiCal::PropertyValue::CalAddress represents an icalendar Date property value
    # which is defined in
    # RFC 2445 section 4.3.4 p 34
    class Date < PropertyValue

      def self.valid_string?(string) #:nodoc:
        string =~ /^\d{8}$/
      end

      # Returns the value of the reciever as an RFC 2445 iCalendar string
      def value
        if @date_time_value
          @date_time_value.ical_date_str
        else
          nil
        end
      end
      
      def to_ri_cal_zulu_date_time
        self.to_ri_cal_date_time_value.to_ri_cal_zulu_date_time
      end

      # Set the value of the property to val
      #
      # val may be either:
      #
      # * A string which can be parsed as a DateTime
      # * A Time instance
      # * A Date instance
      # * A DateTime instance
      def value=(val)
        case val
        when nil
          @date_time_value = nil
        when String
          @date_time_value = FastDateTime.from_date_time(::DateTime.parse(::DateTime.parse(val).strftime("%Y%m%d")))
        when ::Time, ::Date, ::DateTime
          @date_time_value = FastDateTime.from_date_time(::DateTime.parse(val.strftime("%Y%m%d")))
        when FastDateTime
          @date_time_value = val
        end
      end

      # Nop to allow occurrence list to try to set it
      def tzid=(val)#:nodoc:
      end

      def tzid #:nodoc:
        nil
      end

      def visible_params #:nodoc:
        {"VALUE" => "DATE"}.merge(params)
      end

      # Returns the year (including the century)
      def year
        @date_time_value.year
      end

      # Returns the month of the year (1..12)
      def month
        @date_time_value.month
      end

      # Returns the day of the month
      def day
        @date_time_value.day
      end

      # Returns the ruby representation a ::Date
      def ruby_value
        @date_time_value.date
      end

      alias_method :to_ri_cal_ruby_value, :ruby_value

      # Return an instance of RiCal::PropertyValue::DateTime representing the start of this date
      def to_ri_cal_date_time_value
        PropertyValue::DateTime.new(timezone_finder, :value => @date_time_value)
      end

      # Return this date property
      def to_ri_cal_date_value(timezone_finder = nil)
        self
      end

      # Return the "Natural' property value for the date_property, in this case the date property itself."
      def to_ri_cal_date_or_date_time_value
        self
      end

      def for_parent(parent) #:nodoc:
        if timezone_finder.nil?
          @timezone_finder = parent
          self
        elsif parent == timezone_finder
          self
        else
          Date.new(parent, :value => @date_time_value)
        end
      end

      def advance(options) #:nodoc:
        PropertyValue::Date.new(timezone_finder, :value => @date_time_value.advance(options), :params =>(params ? params.dup : nil) )
      end

      def change(options) #:nodoc:
        PropertyValue::Date.new(timezone_finder,:value => @date_time_value.change(options), :params => (params ? params.dup : nil) )
      end

      def add_date_times_to(required_timezones) #:nodoc:
        # Do nothing since dates don't have a timezone
      end

      # Return the difference between the receiver and other
      #
      # The parameter other should be either a RiCal::PropertyValue::Duration or a RiCal::PropertyValue::DateTime
      #
      # If other is a Duration, the result will be a DateTime, if it is a DateTime the result will be a Duration
      def -(other)
        other.subtract_from_date_time_value(to_ri_cal_date_time_value)
      end

      def subtract_from_date_time_value(date_time)
        to_ri_cal_date_time_value.subtract_from_date_time_value(date_time)
      end

      # Return the sum of the receiver and duration
      #
      # The parameter other duration should be  a RiCal::PropertyValue::Duration
      #
      # The result will be an RiCal::PropertyValue::DateTime
      def +(duration)
        duration.add_to_date_time_value(to_ri_cal_date_time_value)
      end

      # Delegate unknown messages to the wrappered Date instance.
      # TODO: Is this really necessary?
      def method_missing(selector, *args) #:nodoc:
        @date_time_value.send(selector, *args)
      end

      # TODO: consider if this should be a period rather than a hash
      def occurrence_period(default_duration) #:nodoc:
        date_time = self.to_ri_cal_date_time_value
        RiCal::OccurrencePeriod.new(date_time, date_time.advance(:hours => 24, :seconds => -1))
      end

      def start_of_day?
        true
      end

      def to_floating_date_time_property
        PropertyValue::DateTime.new(timezone_finder, :value => @date_time_value.ical_str)
      end

      def to_zulu_occurrence_range_start_time
        to_floating_date_time_property.to_zulu_occurrence_range_start_time
      end

      def to_zulu_occurrence_range_finish_time
        to_ri_cal_date_time_value.end_of_day.to_zulu_occurrence_range_finish_time
      end

      def to_finish_time
        to_ri_cal_date_time_value.end_of_day.to_datetime
      end

      def for_occurrence(occurrence)
        if occurrence.start_of_day?
           occurrence.to_ri_cal_date_value(timezone_finder)
        else
          occurrence.for_parent(timezone_finder)
        end
      end
    end
  end
end