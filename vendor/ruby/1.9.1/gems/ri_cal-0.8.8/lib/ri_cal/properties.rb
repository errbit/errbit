module RiCal
  module Properties #:nodoc:
    autoload :Alarm, "ri_cal/properties/alarm.rb"
    autoload :Calendar, "ri_cal/properties/calendar.rb"
    autoload :Event, "ri_cal/properties/event.rb"
    autoload :Freebusy, "ri_cal/properties/freebusy.rb"
    autoload :Journal, "ri_cal/properties/journal.rb"
    autoload :Timezone, "ri_cal/properties/timezone.rb"
    autoload :TimezonePeriod, "ri_cal/properties/timezone_period.rb"
    autoload :Todo, "ri_cal/properties/todo.rb"
  end
end