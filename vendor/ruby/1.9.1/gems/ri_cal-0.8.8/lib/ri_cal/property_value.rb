module RiCal
  #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
  #
  # PropertyValue provides common implementation of various RFC 2445 property value types
  class PropertyValue
    
    autoload :Array, "ri_cal/property_value/array.rb"
    autoload :CalAddress, "ri_cal/property_value/cal_address.rb"
    autoload :Date, "ri_cal/property_value/date.rb"
    autoload :DateTime, "ri_cal/property_value/date_time.rb"
    autoload :Duration, "ri_cal/property_value/duration.rb"
    autoload :Geo, "ri_cal/property_value/geo.rb"
    autoload :Integer, "ri_cal/property_value/integer.rb"
    autoload :OccurrenceList, "ri_cal/property_value/occurrence_list.rb"
    autoload :Period, "ri_cal/property_value/period.rb"
    autoload :RecurrenceRule, "ri_cal/property_value/recurrence_rule.rb"
    autoload :Text, "ri_cal/property_value/text.rb"
    autoload :Uri, "ri_cal/property_value/uri.rb"
    autoload :UtcOffset, "ri_cal/property_value/utc_offset.rb"
    autoload :ZuluDateTime, "ri_cal/property_value/zulu_date_time.rb"

    attr_writer :params, :value #:nodoc:
    attr_reader :timezone_finder #:nodoc:
    def initialize(timezone_finder, options={}) # :nodoc:
      @timezone_finder = timezone_finder
      validate_value(options)
      ({:params => {}}).merge(options).each do |attribute, val|
        unless attribute == :name
          setter = :"#{attribute.to_s.downcase}="
          send(setter, val)
        end
      end
    end
    
    def self.if_valid_string(timezone_finder, string) #:nodoc:
      if valid_string?(string)
        new(timezone_finder, :value => string)
      else
        nil
      end
    end

    def validate_value(options) #:nodoc:
      val = options[:value]
      raise "Invalid property value #{val.inspect}" if val.kind_of?(String) && /^;/.match(val)
    end

    # return a hash containing the parameters and values, if any
    def params
      @params ||= {}
    end

    def to_options_hash #:nodoc:
      options_hash = {:value => value}
      options_hash[:params] = params unless params.empty?
    end
    
    def self.date_or_date_time(timezone_finder, separated_line) # :nodoc:
      match = separated_line[:value].match(/(\d\d\d\d)(\d\d)(\d\d)((T?)((\d\d)(\d\d)(\d\d))(Z?))?/)
      raise Exception.new("Invalid date") unless match
      if match[5] == "T" # date-time
        time = Time.utc(match[1].to_i, match[2].to_i, match[3].to_i, match[7].to_i, match[8].to_i, match[9].to_i)
        parms = (separated_line[:params] ||{}).dup
        if match[10] == "Z"
          raise Exception.new("Invalid time, cannot combine Zulu with timezone reference") if parms[:tzid]
          parms['TZID'] = "UTC"
        end
        PropertyValue::DateTime.new(timezone_finder, separated_line.merge(:params => parms))
      else
        PropertyValue::Date.new(timezone_finder, separated_line)
      end
    end
    
    def self.date_or_date_time_or_period(timezone_finder, separated_line) #:nodoc:
      if separated_line[:value].include?("/")
        PropertyValue::Period.new(timezone_finder, separated_line)
      else
        date_or_date_time(timezone_finder, separated_line)
      end
    end

    # def self.from_string(string) # :nodoc:
    #   new(nil, :value => string)
    # end

    def self.convert(timezone_finder, value) #:nodoc:
      new(timezone_finder, :value => value)
    end

    # Determine if another object is equivalent to the receiver.
    def ==(o)
      if o.class == self.class
        equality_value == o.equality_value
      else
        super
      end
    end

    # Return the string value
    def value
      @value
    end

    def equality_value #:nodoc:
      value
    end

    def visible_params # :nodoc:
      params
    end

    def parms_string #:nodoc:
      if (vp = visible_params) && !vp.empty?
        # We only sort for testability reasons
        vp.keys.sort.map {|key| ";#{key}=#{vp[key]}"}.join
      else
        ""
      end
    end

    # Return a string representing the receiver in RFC 2445 format
    def to_s #:nodoc:
      "#{parms_string}:#{value}"
    end

    # return the ruby value
    def ruby_value
      self.value
    end

    def to_ri_cal_property_value #:nodoc:
      self
    end
    
    def find_timezone(timezone_identifier) #:nodoc:
      if timezone_finder
        timezone_finder.find_timezone(timezone_identifier)
      else
        raise "Unable to find timezone with tzid #{timezone_identifier}"
      end
    end
    
    def default_tzid #:nodoc:
      if timezone_finder
        timezone_finder.default_tzid
      else
        PropertyValue::DateTime.default_tzid
      end
    end
    
    def tz_info_source? #:nodoc:
      if timezone_finder
        timezone_finder.tz_info_source?
      else
        true
      end
    end
  end
end
