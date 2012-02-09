#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
#
# The RiCal module provides the outermost namespace, along with several convenience methods for parsing
# and building calendars and calendar components.
module RiCal
  
  require 'stringio'
  require 'rational'
  
  my_dir =  File.dirname(__FILE__)
  
  $LOAD_PATH << my_dir unless $LOAD_PATH.include?(my_dir)

  if Object.const_defined?(:ActiveSupport)
    as = Object.const_get(:ActiveSupport)
    if as.const_defined?(:TimeWithZone)
      time_with_zone = as.const_get(:TimeWithZone)
    end
  end
  
  # TimeWithZone will be set to ActiveSupport::TimeWithZone if the activesupport gem is loaded
  # otherwise it will be nil
  TimeWithZone = time_with_zone  
  
  autoload :Component, "ri_cal/component.rb"
  autoload :CoreExtensions, "ri_cal/core_extensions.rb" 
  autoload :FastDateTime, "ri_cal/fast_date_time.rb" 
  autoload :FloatingTimezone, "ri_cal/floating_timezone.rb" 
  autoload :InvalidPropertyValue, "ri_cal/invalid_property_value.rb" 
  autoload :InvalidTimezoneIdentifier, "ri_cal/invalid_timezone_identifier.rb" 
  autoload :OccurrenceEnumerator, "ri_cal/occurrence_enumerator.rb"
  autoload :OccurrencePeriod, "ri_cal/occurrence_period.rb"
  autoload :TimezonePeriod, "ri_cal/properties/timezone_period.rb"
  autoload :Parser, "ri_cal/parser.rb"
  autoload :Properties, "ri_cal/properties.rb"
  autoload :PropertyValue, "ri_cal/property_value.rb" 
  autoload :RequiredTimezones, "ri_cal/required_timezones.rb" 
  require "ri_cal/core_extensions.rb"
  # :stopdoc:
  VERSION = '0.8.5'
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end

  # Returns the library path for the module. If any arguments are given,
  # they will be joined to the end of the libray path using
  # <tt>File.join</tt>.
  #
  def self.libpath( *args )
    args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
  end

  # Returns the lpath for the module. If any arguments are given,
  # they will be joined to the end of the path using
  # <tt>File.join</tt>.
  #
  def self.path( *args )
    args.empty? ? PATH : ::File.join(PATH, args.flatten)
  end

  # Utility method used to rquire all files ending in .rb that lie in the
  # directory below this file that has the same name as the filename passed
  # in. Optionally, a specific _directory_ name can be passed in such that
  # the _filename_ does not have to be equivalent to the directory.
  #
  def self.require_all_libs_relative_to( fname, dir = nil )
    dir ||= ::File.basename(fname, '.*')
    search_me = ::File.expand_path(::File.join(::File.dirname(fname), dir, '**', '*.rb'))
    Dir.glob(search_me).sort.each {|rb|
      require rb}
  end
  
  # :startdoc:
  
  # Parse an io stream and return an array of iCalendar entities.
  # Normally this will be an array of RiCal::Component::Calendar instances
  def self.parse(io)
    Parser.new(io).parse
  end
  
  # Parse a string and return an array of iCalendar entities.
  # see RiCal.parse
  def self.parse_string(string)
    parse(StringIO.new(string))
  end
  
  def self.debug # :nodoc:
    @debug
  end
  
  def self.debug=(val) # :nodoc:
    @debug = val
  end
 
  # return a new Alarm event or todo component.  If a block is provided it will will be executed in
  # the context of a builder object which can be used to initialize the properties of the 
  # new Alarm.  
  def self.Alarm(&init_block)
    Component::Alarm.new(&init_block)
  end
  
  # return a new Calendar.  If a block is provided it will will be executed in
  # the context of a builder object which can be used to initialize the properties and components of the 
  # new calendar.  
  def self.Calendar(&init_block)
    Component::Calendar.new(&init_block)
  end

  # return a new Event calendar component.  If a block is provided it will will be executed in
  # the context of a builder object which can be used to initialize the properties and alarms of the 
  # new Event.  
  def self.Event(&init_block)
    Component::Event.new(&init_block)
  end

  # return a new Freebusy calendar component.  If a block is provided it will will be executed in
  # the context of a builder object which can be used to initialize the properties and components of the 
  # new Freebusy.  
  def self.Freebusy(&init_block)
    Component::Freebusy.new(&init_block)
  end

  # return a new Journal calendar component.  If a block is provided it will will be executed in
  # the context of a builder object which can be used to initialize the properties and components of the 
  # new Event.  
  def self.Journal(&init_block)
    Component::Journal.new(&init_block)
  end

  # return a new Timezone calendar component.  If a block is provided it will will be executed in
  # the context of a builder object which can be used to initialize the properties and timezone periods of the 
  # new Timezone.  
  def self.Timezone(&init_block)
    Component::Timezone.new(&init_block)
  end

  # return a new TimezonePeriod timezone component.  If a block is provided it will will be executed in
  # the context of a builder object which can be used to initialize the properties of the 
  # new TimezonePeriod.  
  def self.TimezonePeriod(&init_block)
    Component::TimezonePeriod.new(&init_block)
  end

  # return a new Todo calendar component.  If a block is provided it will will be executed in
  # the context of a builder object which can be used to initialize the properties and alarms of the 
  # new Todo.  
  def self.Todo(&init_block)
    Component::Todo.new(&init_block)
  end
  
  def self.ro_calls=(value)
    @ro_calls = value
  end
  
  def self.ro_calls
    @ro_calls ||= 0
  end
  
  def self.ro_misses=(value)
    @ro_misses = value
  end
  
  def self.ro_misses
    @ro_misses ||= 0
  end
  
  def self.RationalOffset
    self.ro_calls += 1
    @rational_offset ||= Hash.new {|h, seconds|
      self.ro_misses += 1
      h[seconds] = Rational(seconds, 86400)}
  end

end  # module RiCal

(-12..12).each do |hour_offset|
  RiCal.RationalOffset[hour_offset * 86400]
end


#RiCal.require_all_libs_relative_to(__FILE__)
# EOF
