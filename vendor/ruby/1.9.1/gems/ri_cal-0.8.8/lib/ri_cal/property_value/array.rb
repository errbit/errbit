module RiCal
  class PropertyValue
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    class Array < PropertyValue # :nodoc:

      def value=(val)
        case val
        when String
          @value = val.split(",")
        else
          @value = val
        end
      end
      
      def value
        @value.join(",")
      end
      
      def self.convert(timezone_finder, ruby_object) # :nodoc:
        self.new(timezone_finder, :value => ruby_object)
      end
      
    end
  end

end