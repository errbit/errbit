module RiCal
  module CoreExtensions #:nodoc:
    module Array #:nodoc:
      #- ©2009 Rick DeNatale
      #- All rights reserved. Refer to the file README.txt for the license
      #
      module Conversions
        # return the concatenation of the elements representation in rfc 2445 format
        def to_rfc2445_string # :doc:
          join(",")
        end
      end
    end
  end
end