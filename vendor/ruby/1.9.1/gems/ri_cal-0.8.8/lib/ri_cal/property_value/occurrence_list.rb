module RiCal
  class PropertyValue
    # OccurrenceList is used to represent the value of an RDATE or EXDATE property.
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    class OccurrenceList < Array
      attr_accessor :tzid #:nodoc:

      class Enumerator # :nodoc:

        attr_accessor :default_duration, :occurrence_list

        # TODO: the component parameter should always be the parent
        def initialize(occurrences, component) # :nodoc:
          self.occurrence_list = occurrences
          self.default_duration = component.default_duration
          @index = 0
        end
        
        def bounded?
          true
        end
        
        def empty?
          occurrence_list.empty?
        end

        def next_occurrence
          if @index < occurrence_list.length
            result = occurrence_list[@index].occurrence_period(default_duration)
            @index += 1
            result
          else
            nil
          end
        end
      end

      def initialize(timezone_finder, options={}) # :nodoc:
        super
        validate_elements
      end

      def self.convert(timezone_finder, *ruby_objects) # :nodoc:
        # ruby_objects = [ruby_objects] unless Array === ruby_objects
        source_elements = ruby_objects.inject([]) { |se, element|
          if String === element
            element.split(",").each {|str| se << str}
          else
            se << element
          end
          se
          }        
        new(timezone_finder, :source_elements => source_elements )
      end

      def values_to_elements(values) # :nodoc:
        values.map {|val| val.to_ri_cal_occurrence_list_value(self)}
      end
      
      def tzid_from_source_elements # :nodoc:
        if @source_elements && String === (first_source = @source_elements.first)
          probe = first_source.to_ri_cal_occurrence_list_value rescue nil
          unless probe
            return @source_elements.shift
          end
        end
        nil
      end
      
      def tzid_conflict(element_tzid) # :nodoc:
        element_tzid && tzid != element_tzid
      end
      
      def validate_elements # :nodoc:
        if @source_elements
          self.tzid = tzid_from_source_elements
           @elements = values_to_elements(@source_elements)
          @value = @elements.map {|prop| prop.value}
        else
          @elements = values_to_elements(@value)
          self.tzid = params['TZID']
        end
        # if the tzid wasn't set by the parameters
        self.tzid ||= @elements.map {|element| element.tzid}.find {|id| id}
        @elements.each do |element|
          raise InvalidPropertyValue.new("Mixed timezones are not allowed in an occurrence list") if tzid_conflict(element.tzid)
          element.tzid = tzid
        end
      end

      def has_local_timezone? # :nodoc:
        tzid && tzid != 'UTC'
      end

      def visible_params # :nodoc:
        result = params.dup
        if has_local_timezone?
          result['TZID'] = tzid
        else
          result.delete('TZID')
        end
        result
      end

      def value # :nodoc:
        @elements.map {|element| element.value}.join(",")
      end

      # Return an array of the occurrences within the list
      def ruby_value
        @elements.map {|prop| prop.ruby_value}
      end
    end

    attr_accessor :elements, :source_elements #:nodoc:
    private :elements, :elements=, :source_elements=, :source_elements

    def for_parent(parent) #:nodoc:
      if timezone_finder.nil?
        @timezone_finder = parent
        self
      elsif timezone_finder == parent
        self
      else
        OccurrenceList.new(parent, :value => value)
      end
    end

    # Return an enumerator which can produce the elements of the occurrence list
    def enumerator(component) # :nodoc:
      OccurrenceList::Enumerator.new(@elements, component)
    end

    def add_date_times_to(required_timezones) #:nodoc:
      if @elements
        @elements.each do | occurrence |
          occurrence.add_date_times_to(required_timezones)
        end
      end
    end

  end
end