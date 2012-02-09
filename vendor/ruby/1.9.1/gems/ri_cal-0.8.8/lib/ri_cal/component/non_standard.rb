module RiCal

  class Component
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    # An NonStandard component represents a component (or subcomponent) not listed in RFC2445.
    # For example some icalendar data contains VVENUE components, a proposed extension to RFC2445
    # which was dropped.
    class NonStandard < Component
      attr_reader :entity_name
      
      def initialize(parent, entity_name)
        super(parent)
        @entity_name = entity_name
        @source_lines = []
      end
      
      def process_line(parser, line) #:nodoc:
        if line[:name] == "BEGIN"
          parse_subcomponent(parser, line)
        else
          @source_lines << parser.last_line_str
        end
      end
      
      def export_properties_to(stream)
        @source_lines.each do |line|
          stream.puts(line)
        end
      end
    end
  end
end