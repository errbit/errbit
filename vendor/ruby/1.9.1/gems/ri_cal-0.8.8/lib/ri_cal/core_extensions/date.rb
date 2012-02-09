require "ri_cal/core_extensions/date/conversions.rb"
require "ri_cal/core_extensions/time/week_day_predicates.rb"
require "ri_cal/core_extensions/time/calculations.rb"
require 'date'

class Date #:nodoc:
  #- ©2009 Rick DeNatale
  #- All rights reserved. Refer to the file README.txt for the license
  #
  include RiCal::CoreExtensions::Time::WeekDayPredicates
  include RiCal::CoreExtensions::Time::Calculations
  include RiCal::CoreExtensions::Date::Conversions
end
