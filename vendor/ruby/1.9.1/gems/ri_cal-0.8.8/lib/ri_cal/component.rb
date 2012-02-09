module RiCal
  #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
  #
  class Component #:nodoc:

    autoload :Alarm, "ri_cal/component/alarm.rb"
    autoload :Calendar, "ri_cal/component/calendar.rb"
    autoload :Event, "ri_cal/component/event.rb"
    autoload :Freebusy, "ri_cal/component/freebusy.rb"
    autoload :Journal, "ri_cal/component/journal.rb"
    autoload :NonStandard, "ri_cal/component/non_standard.rb"
    autoload :TZInfoTimezone, "ri_cal/component/t_z_info_timezone.rb"
    autoload :Timezone, "ri_cal/component/timezone.rb"
    autoload :Todo, "ri_cal/component/todo.rb"

    class ComponentBuilder #:nodoc:
      def initialize(component)
        @component = component
      end

      def method_missing(selector, *args, &init_block) #:nodoc:
        if(sub_comp_class = @component.subcomponent_class[selector])
          if init_block
            sub_comp = sub_comp_class.new(@component)
            if init_block.arity == 1
              yield ComponentBuilder.new(sub_comp)
            else
              ComponentBuilder.new(sub_comp).instance_eval(&init_block)
            end
            self.add_subcomponent(sub_comp)
          end
        else
          sel = selector.to_s
          sel = "#{sel}=" unless /(^(add_)|(remove_))|(=$)/ =~ sel
          if @component.respond_to?(sel)
            @component.send(sel, *args)
          else
            super
          end
        end
      end
    end

    attr_accessor :imported #:nodoc:

    def initialize(parent=nil, entity_name = nil, &init_block) #:nodoc:
      @parent = parent
      if block_given?
        if init_block.arity == 1
          init_block.call(ComponentBuilder.new(self))
        else
          ComponentBuilder.new(self).instance_eval(&init_block)
        end
      end
    end

    def default_tzid #:nodoc:
      if @parent
        @parent.default_tzid
      else
        PropertyValue::DateTime.default_tzid
      end
    end

    def find_timezone(identifier) #:nodoc:
      if @parent
        @parent.find_timezone(identifier)
      else
        begin
          Calendar::TZInfoWrapper.new(TZInfo::Timezone.get(identifier), self)
        rescue ::TZInfo::InvalidTimezoneIdentifier => ex
          raise RiCal::InvalidTimezoneIdentifier.invalid_tzinfo_identifier(identifier)
        end
      end
    end

    def tz_info_source?
      if @parent
        @parent.tz_info_source?
      else
        true
      end
    end

    def time_zone_for(ruby_object) #:nodoc:
      @parent.time_zone_for(ruby_object) #:nodoc:
    end

    def subcomponent_class #:nodoc:
      {}
    end

    def self.from_parser(parser, parent, entity_name) #:nodoc:
      entity = self.new(parent, entity_name)
      entity.imported = true
      line = parser.next_separated_line
      while parser.still_in(entity_name, line)
        entity.process_line(parser, line)
        line = parser.next_separated_line
      end
      entity
    end

    def self.parse(io) #:nodoc:
      Parser.new(io).parse
    end

    def imported? #:nodoc:
      imported
    end

    def self.parse_string(string) #:nodoc:
      parse(StringIO.new(string))
    end

    def subcomponents #:nodoc:
      @subcomponents ||= Hash.new {|h, k| h[k] = []}
    end

    def entity_name #:nodoc:
      self.class.entity_name
    end

    # return an array of Alarm components within this component :nodoc:
    # Alarms may be contained within Events, and Todos
    def alarms
      subcomponents["VALARM"]
    end

    def add_subcomponent(component) #:nodoc:
      subcomponents[component.entity_name] << component
    end

    def parse_subcomponent(parser, line) #:nodoc:
      subcomponents[line[:value]] << parser.parse_one(line, self)
    end

    def process_line(parser, line) #:nodoc:
      if line[:name] == "BEGIN"
        parse_subcomponent(parser, line)
      else
        setter = self.class.property_parser[line[:name]]
        if setter
          send(setter, line)
        else
          self.add_x_property(line[:name], PropertyValue::Text.new(self, line))
        end
      end
    end

    # return a hash of any extended properties, (i.e. those with a property name starting with "X-"
    # representing an extension to the RFC 2445 specification)
    def x_properties
      @x_properties ||= Hash.new {|h,k| h[k] = []}
    end

    # Add a n extended property
    def add_x_property(name, prop, debug=false)
      x_properties[name.gsub("_","-").upcase] << prop.to_ri_cal_text_property
    end

    def method_missing(selector, *args, &b) #:nodoc:
      xprop_candidate = selector.to_s
      if (match = /^(x_.+)(=?)$/.match(xprop_candidate))
        x_property_key = match[1].gsub('_','-').upcase
        if match[2] == "="
          args.each do |val|
            add_x_property(x_property_key, val)
          end
        else
          x_properties[x_property_key].map {|property| property.value}
        end
      else
        super
      end
    end

    # Predicate to determine if the component is valid according to RFC 2445
    def valid?
      !mutual_exclusion_violation
    end

    def initialize_copy(original) #:nodoc:
    end

    def prop_string(prop_name, *properties) #:nodoc:
      properties = properties.flatten.compact
      if properties && !properties.empty?
        properties.map {|prop| "#{prop_name}#{prop.to_s}"}.join("\n")
      else
        nil
      end
    end

    def add_property_date_times_to(required_timezones, property) #:nodoc:
      if property
        if Array === property
          property.each do |prop|
            prop.add_date_times_to(required_timezones)
          end
        else
          property.add_date_times_to(required_timezones)
        end
      end
    end

    def export_prop_to(export_stream, name, prop) #:nodoc:
      if prop
        string = prop_string(name, prop)
        export_stream.puts(string) if string
      end
    end

    def export_x_properties_to(export_stream) #:nodoc:
      x_properties.each do |name, props|
        props.each do | prop |
          export_stream.puts("#{name}:#{prop}")
        end
      end
    end

    def export_subcomponent_to(export_stream, subcomponent) #:nodoc:
      subcomponent.each do |component|
        component.export_to(export_stream)
      end
    end

    # return a string containing the rfc2445 format of the component
    def to_s
      io = StringIO.new
      export_to(io)
      io.string
    end

    # Export this component to an export stream
    def export_to(export_stream)
      export_stream.puts("BEGIN:#{entity_name}")
      export_properties_to(export_stream)
      export_x_properties_to(export_stream)
      subcomponents.values.each do |sub|
        export_subcomponent_to(export_stream, sub)
      end
      export_stream.puts("END:#{entity_name}")
    end

    # Export this single component as an iCalendar component containing only this component and
    # any required additional components (i.e. VTIMEZONES referenced from this component)
    # if stream is nil (the default) then this method will return a string,
    # otherwise stream should be an IO to which the iCalendar file contents will be written
    def export(stream=nil)
      wrapper_calendar = Calendar.new
      wrapper_calendar.add_subcomponent(self)
      wrapper_calendar.export(stream)
    end
  end
end