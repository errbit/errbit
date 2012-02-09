module RiCal

  class Component
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    # An Alarm component groups properties defining a reminder or alarm associated with an event or to-do
    # TODO: The Alarm component has complex cardinality restrictions depending on the value of the action property
    # i.e. audio, display, email, and proc alarms, this is currently not checked or enforced
    #
    # to see the property accessing methods for this class see the RiCal::Properties::Alarm module
    class Alarm < Component
      include RiCal::Properties::Alarm

      def self.entity_name #:nodoc:
        "VALARM"
      end
    end
  end
end