module RiCal
  #- ©2009 Rick DeNatale
  #- All rights reserved. Refer to the file README.txt for the license
  #
  # An InvalidTimezoneIdentifier error is raised when a DATETIME property with an invalid timezone is
  # involved in a timezone conversion operation
  #
  # Rather than attempting to detect invalid timezones immediately the detection is deferred to avoid problems
  # such as importing a calendar which has forward reference to VTIMEZONE components.
  class InvalidTimezoneIdentifier < StandardError
    
    def self.not_found_in_calendar(identifier) #:nodoc:
      new("#{identifier.inspect} is not the identifier of a VTIMEZONE component of this calendar")
    end
    
    def self.invalid_tzinfo_identifier(identifier) #:nodoc:
      new("#{identifier.inspect} is not known to the tzinfo database")
    end
  end
end
