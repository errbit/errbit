module RiCal
  module CoreExtensions #:nodoc:
    module Object #:nodoc:
      #- ©2009 Rick DeNatale
      #- All rights reserved. Refer to the file README.txt for the license
      #
      module Conversions #:nodoc:
        # Used to format rfc2445 output for RiCal
        def to_rfc2445_string
          to_s
        end
        
        # Used by RiCal specs returns the receiver
        def to_ri_cal_ruby_value
          self
        end
      end
    end
  end
end