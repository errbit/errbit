module RiCal
  module CoreExtensions #:nodoc:
    module Date #:nodoc:
      #- ©2009 Rick DeNatale
      #- All rights reserved. Refer to the file README.txt for the license
      #
      module Conversions #:nodoc:
        # Return an RiCal::PropertyValue::DateTime representing the receiver
        def to_ri_cal_date_time_value(timezone_finder = nil)
          RiCal::PropertyValue::DateTime.new(timezone_finder, :value => self)
        end
        
        # Return an RiCal::PropertyValue::Date representing the receiver
        def to_ri_cal_date_value(timezone_finder = nil)
          RiCal::PropertyValue::Date.new(timezone_finder, :value => self)
        end

        alias_method :to_ri_cal_date_or_date_time_value, :to_ri_cal_date_value
        alias_method :to_ri_cal_occurrence_list_value, :to_ri_cal_date_value
        
        # Return the natural ri_cal_property for this object
        def to_ri_cal_property_value(timezone_finder = nil)
          to_ri_cal_date_value(timezone_finder)
        end
        
        def to_overlap_range_start
          to_datetime
        end
        
        def to_overlap_range_end
          to_ri_cal_date_time_value.end_of_day.to_datetime
        end
        
        unless Date.instance_methods.map {|selector| selector.to_sym}.include?(:to_date)
          # A method to keep Time, Date and DateTime instances interchangeable on conversions.
          # In this case, it simply returns +self+.
          def to_date
            self
          end
        end
        unless Date.instance_methods.map {|selector| selector.to_sym}.include?(:to_datetime)
          # Converts a Date instance to a DateTime, where the time is set to the beginning of the day
          # and UTC offset is set to 0.
          #
          # ==== Examples
          #   date = Date.new(2007, 11, 10)  # => Sat, 10 Nov 2007
          #
          #   date.to_datetime               # => Sat, 10 Nov 2007 00:00:00 0000
          def to_datetime
            ::DateTime.civil(year, month, day, 0, 0, 0, 0)
          end
        end
      end
    end
  end
end