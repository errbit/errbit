module RiCal
  module CoreExtensions #:nodoc:
    module Time #:nodoc:
      #- ©2009 Rick DeNatale
      #- All rights reserved. Refer to the file README.txt for the license
      #
      module Conversions
        # Return an RiCal::PropertyValue::DateTime representing the receiver
        def to_ri_cal_date_time_value(timezone_finder = nil) #:nodoc:
          RiCal::PropertyValue::DateTime.new(
               timezone_finder, 
               :value => strftime("%Y%m%dT%H%M%S"), 
               :params => {"TZID" => self.tzid || :default})
        end

        alias_method :to_ri_cal_date_or_date_time_value, :to_ri_cal_date_time_value #:nodoc:
        alias_method :to_ri_cal_occurrence_list_value, :to_ri_cal_date_time_value #:nodoc:

        # Return the natural ri_cal_property for this object
        def to_ri_cal_property_value(timezone_finder = nil) #:nodoc:
          to_ri_cal_date_time_value(timezone_finder)
        end
        
        def to_overlap_range_start
          to_datetime
        end
        
        alias_method :to_overlap_range_end, :to_overlap_range_start
        
        # Return a copy of this object which will be interpreted as a floating time.
        def with_floating_timezone
          dup.set_tzid(:floating)
        end
        
        unless Time.instance_methods.map {|selector| selector.to_sym}.include?(:to_datetime)
          require 'date'
          ::Time.send(:public, :to_datetime)
        end
      end
    end
  end
end