module RiCal
  class PropertyValue
    class DateTime
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      # Methods for DateTime which support adding or subtracting another DateTime or Duration
      module AdditiveMethods
        #  if end_time is nil => nil
        #  otherwise convert end_time to a DateTime and compute the difference
        def duration_until(end_time) # :nodoc:
          end_time  && RiCal::PropertyValue::Duration.from_datetimes(timezone_finder, to_datetime, end_time.to_datetime)
        end

        # Double-dispatch method for subtraction.
        def subtract_from_date_time_value(dtvalue) #:nodoc:
          RiCal::PropertyValue::Duration.from_datetimes(timezone_finder, to_datetime,dtvalue.to_datetime)
        end

        # Double-dispatch method for addition.
        def add_to_date_time_value(date_time_value) #:nodoc:
          raise ArgumentError.new("Cannot add #{date_time_value} to #{self}")
        end

        # Return the difference between the receiver and other
        #
        # The parameter other should be either a RiCal::PropertyValue::Duration or a RiCal::PropertyValue::DateTime
        #
        # If other is a Duration, the result will be a DateTime, if it is a DateTime the result will be a Duration
        def -(other)
          other.subtract_from_date_time_value(self)
        end

        # Return the sum of the receiver and duration
        #
        # The parameter other duration should be  a RiCal::PropertyValue::Duration
        #
        # The result will be an RiCal::PropertyValue::DateTime
        def +(duration)
          duration.add_to_date_time_value(self)
        end
      end
    end
  end
end