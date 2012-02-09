module RiCal
  class Component
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    #  A Freebusy (VFREEBUSY) calendar component groups properties describing either a request for free/busy time,
    #  a response to a request for free/busy time, or a published set of busy time.
    # to see the property accessing methods for this class see the RiCal::Properties::Freebusy module
    class Freebusy < Component
      include RiCal::Properties::Freebusy        

      def self.entity_name #:nodoc:
        "VFREEBUSY"
      end
    end 
  end
end