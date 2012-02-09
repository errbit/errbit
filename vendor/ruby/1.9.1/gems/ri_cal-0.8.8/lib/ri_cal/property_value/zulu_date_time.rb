require 'date'
module RiCal
  class PropertyValue
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    # RiCal::PropertyValue::CalAddress represents an icalendar CalAddress property value
    # which is defined in RFC 2445 section 4.3.5 pp 35-37
    class ZuluDateTime < PropertyValue::DateTime
      
      def tzid
        "UTC"
      end

      def value=(val) # :nodoc:
        if DateTime === val
          @date_time_value = val
        else
          super(val)
        end
        @date_time_value = @date_time_value.utc if @date_time_value
      end
      
      def to_ri_cal_zulu_date_time
        self
      end
      
      def self.convert(timezone_finder, ruby_object) # :nodoc:
          result = super
          result.to_ri_cal_zulu_date_time
      end
      
    end
  end
end