module RiCal
  class PropertyValue
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    class Integer < PropertyValue # :nodoc:

      def value=(string)
        @value = string.to_i 
      end
    end
  end
end