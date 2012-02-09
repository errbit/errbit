#- ©2009 Rick DeNatale
#- All rights reserved. Refer to the file README.txt for the license
#
require "ri_cal/core_extensions/time/conversions.rb"
require "ri_cal/core_extensions/time/tzid_access.rb"
require "ri_cal/core_extensions/time/week_day_predicates.rb"
require "ri_cal/core_extensions/time/calculations.rb"

class Time #:nodoc:
  include RiCal::CoreExtensions::Time::WeekDayPredicates
  include RiCal::CoreExtensions::Time::Calculations  
  include RiCal::CoreExtensions::Time::Conversions
  include RiCal::CoreExtensions::Time::TzidAccess
end