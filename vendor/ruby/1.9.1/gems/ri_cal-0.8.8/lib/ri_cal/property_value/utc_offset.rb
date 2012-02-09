module RiCal
  class PropertyValue
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    class UtcOffset < PropertyValue # :nodoc:
      attr_accessor :sign, :hours, :minutes, :seconds

      def value=(string)
        @value = string
        parse_match = /([+-])(\d\d)(\d\d)(\d\d)?/.match(string)
        if parse_match
          @sign = parse_match[1] == "+" ? 1 : -1
          @hours = parse_match[2].to_i
          @minutes = parse_match[3].to_i
          @seconds = parse_match[4].to_i || 0
        end
      end
      
      def to_seconds
        @sign * ((((hours*60) + minutes) * 60) + seconds)
      end
      
      def add_to_date_time_value(date_time_value)
        date_time_value.advance(:hours => sign * hours, :minutes => sign * minutes, :seconds => sign * minutes)
      end
      
      def subtract_from_date_time_value(date_time_value)
        signum = -1 * sign
        date_time_value.advance(:hours => signum * hours, :minutes => signum * minutes, :seconds => signum * minutes)
      end
    end
  end
end