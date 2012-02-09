== RI_CAL -- a new implementation of RFC2445 in Ruby
http://ri-cal.rubyforge.org/

    by Rick DeNatale
== DESCRIPTION:

A new Ruby implementation of RFC2445 iCalendar.

The existing Ruby iCalendar libraries (e.g. icalendar, vpim) provide for parsing and generating icalendar files,
but do not support important things like enumerating occurrences of repeating events.

This is a clean-slate implementation of RFC2445.

A Google group for discussion of this library has been set up http://groups.google.com/group/rical_gem

== FEATURES/PROBLEMS:

* All examples of recurring events in RFC 2445 are handled. RSpec examples are provided for them. 

== SYNOPSIS:

For the full RDOC see http://ri-cal.rubyforge.org/rdoc/

=== Components and properties

An iCalendar calendar comprises subcomponents like Events, Timezones and Todos. Each component may
have properties, for example an event has a dtstart property which defines the time (and date) on
which the event starts.

RiCal components will provide reasonable ruby objects as the values of these properties, and allow
the properties to be set to ruby objects which are reasonable for the particular property. For
example time properties like dtstart can be set to a ruby Time, DateTime or Date object, and will
return a DateTime or Date object when queried.

The methods for accessing the properties of each type of component are defined in a module with the
same name as the component class in the RiCal::properties module. For example the property
accessing methods for RiCal::Component::Event are defined in RiCal::Properties::Event

=== Creating Calendars and Calendar Components

RiCal provides a builder DSL for creating calendars and calendar components. An example

  RiCal.Calendar do
    event do
      description "MA-6 First US Manned Spaceflight"
      dtstart     DateTime.parse("2/20/1962 14:47:39")
      dtend       DateTime.parse("2/20/1962 19:43:02")
      location    "Cape Canaveral"
      add_attendee "john.glenn@nasa.gov"
      alarm do
        description "Segment 51"
      end
    end
  end
  
This style is for compatibility with the iCalendar and vpim to ease migration. The downside is that
the block is evaluated in the context of a different object which can cause surprises if the block
contains direct instance variable references or implicit references to self. Note that, in this
style, one must use 'declarative' method calls like dtstart to set values rather than more natural
attribute writer methods, like dtstart=
  
Alternatively you can pass a block with a single argument, in this case the component being built
will be passed as that argument

  RiCal.Calendar do |cal|
    cal.event do |event|
      event.description = "MA-6 First US Manned Spaceflight"
      event.dtstart =  DateTime.parse("2/20/1962 14:47:39")
      event.dtend = DateTime.parse("2/20/1962 19:43:02")
      event.location = "Cape Canaveral"
      event.add_attendee "john.glenn@nasa.gov"
      event.alarm do
        description "Segment 51"
      end
    end
  end

As the example shows, the two styles can be mixed, the inner block which builds the alarm uses the
first style.
  
The blocks are evaluated in the context of an object which builds the calendar or calendar
component. method names starting with add_ or remove_ are sent to the component, method names which
correspond to a property value setter of the object being built will cause that setter to be sent
to the component with the provided value.

A method corresponding to the name of one of the components sub component will create the sub
component and evaluate a block if given in the context of the new subcomponent.

==== Multiply occurring properties

Certain RFC Components have properties which may be specified multiple times, for example, an Event
may have zero or more comment properties, A component will have a family of methods for
building/manipulating such a property, e.g.

Event#comment::         will return an array of comment strings.
Event#comment=::        takes a single comment string and gives the event a single comment property, 
                        replacing any existing comment property collection.
Event#comments=::       takes multiple comment string arguments and gives the event a comment property for each,
                        replacing any existing comment property collection.
Event#add_comment::     takes a single comment string argument and adds a comment property.
Event#add_comments::    takes multiple comment string arguments and adds a comment property for each.
Event#remove_comment::  takes a single comment string argument and removes an existing comment property with that value.
Event#remove_comments:: takes multiple comment string argument and removes an existing comment property with that value.


==== Times, Time zones, and Floating Times

RFC2445 describes three different kinds of DATE-TIME values with respect to time zones:

  1. date-times with a local time. These have no actual time zone, instead they are to be 
     interpreted in the local time zone of the viewer.  These floating times are used for things 
     like the New Years celebration which is observed at local midnight whether you happen to be
     in Paris, London, or New York.

  2. date-times with UTC time.  An application would either display these with an indication of 
     the time zone, or convert them to the viewer's time zone, perhaps depending on user settings.

  3. date-times with a specified time zone.

RiCal can be given ruby Time, DateTime, or Date objects for the value of properties requiring an 
iCalendar DATE-TIME value.  It can also be given a string

Note that a date only DATE-TIME value has no time zone by definition, effectively such values float
and describe a date as viewed by the user in his/her local time zone.

When a Ruby Time or DateTime instance is used to set properties with with a DATE-TIME value, it
needs to determine which of the three types it represents. RiCal is designed to make use of the
TimeWithZone support which has been part of the ActiveSupport component of Ruby on Rails since
Rails 2.2. However it's been carefully designed not to require Rails or ActiveSupport, but to
dynamically detect the presence of the TimeWithZone support.

RiCal adds accessor methods for a tzid attribute to the Ruby Time, and DateTime classes as well as
a set_tzid method which sets the tzid attribute and returns the receiver for convenience in
building calendars. If ActiveSupport::TimeWithZone is defined, a tzid instance method is defined
which returns the identifier of the time zone.

When the value of a DATE-TIME property is set to a value, the following processing occurs:

  * If the value is a string, then it must be a valid rfc 2445 date or datetime string optionally
    preceded by a parameter specification e.g
  
    "20010911"  will be interpreted as a date
  
    "20090530T123000Z"  will be interpreted as the time May 30, 2009 at 12:30:00 UTC
  
    "20090530T123000"  will be interpreted as the time May 30, 2009 with a floating time zone
  
    "TZID=America/New_York:20090530T123000"  will be interpreted as the time May 30, 2009 in the time zone identified by "America/New_York"
  
  * If the value is a Date it will be interpreted as that date
  * If the value is a Time, DateTime, or TimeWithZone then the tzid attribute will determine the
    time zone. If tzid returns nil then the default tzid will be used.
  
==== Default TZID

The PropertyValue::DateTime class has a default_tzid attribute which is initialized to "UTC".

The Component::Calendar class also has a default_tzid attribute, which may be set, but if it is not
set the default_tzid of the PropertyValue::DateTime class will be used.

To set the interpreting of Times and DateTimes which have no tzid as floating times, set the
default_tzid for Component::Calendar and/or PropertyValue::DateTime to :floating.

Also note that time zone identifiers are not standardized by RFC 2445. For an RiCal originated
calendar time zone identifiers recognized by the TZInfo gem, or the TZInfo implementation provided
by ActiveSupport as the case may be may be used. The valid time zone identifiers for a non-RiCal
generated calendar imported into RiCalendar are determined by the VTIMEZONE compoents within the
imported calendar.

If you use a timezone identifer within a calendar which is not defined within the calendar it will
detected at the time you try to convert a timezone. In this case an InvalidTimezoneIdentifier error
will be raised by the conversion method.

To explicitly set a floating time you can use the method #with_floating_timezone on Time or
DateTime instances as in

   event.dtstart = Time.parse("1/1/2010 00:00:00").with_floating_timezone
   
or the equivalent

event.dtstart = Time.parse("1/1/2010 00:00:00").set_tzid(:floating)

=== RiCal produced Calendars and Tzinfo

Calendars created by the RiCal Builder DSL use TZInfo as a source of time zone definition
information. RFC 2445 does not specify standard names for time zones, so each time zone identifier
(tzid) within an icalendar data stream must correspond to a VTIMEZONE component in that data
stream.

When an RiCal calendar is exported to an icalendar data stream, the needed VTIMEZONE components
will be generated. In addition a parameter is added to the PRODID property of the calendar which
identifies that the source of tzids is tzinfo. For purposes of this documentation such a calendar
is called a tzinfo calendar.

When RiCal imports an icalendar data stream produced by another library or application, such as
Apple's ical.app, or Google mail, it will be recognized as not being a non-tzinfo calendar, and any
tzids will be resolved using the included VTIMEZONEs. Note that these calendars may well use tzids
which are not recognizable by the tzinfo gem or by the similar code provided by ActiveSupport,
so care is needed in using them.

=== Ruby values of DATETIME properties

The result of accessing the value of a DATETIME property (e.g. event.dtstart) depends on several
factors:

 * If the property has a DATE value, then the result will be a Ruby Date object.

 * Otherwise, if the property has a DATETIME value with a floating timezone, then the result will
   be a Ruby DateTime object, the tzid attribute will be set to :floating, and will respond
   truthily to has_floating_timezone?

 * Otherwise if the value is attached to a property contained in a non-tzinfo calendar, or if the
   ActiveSupport gem is not loaded, then the result will be a Ruby DateTime object, with the proper
   offset from UTC, and with the tzid property set.

 * Finally, if the value is attached to a property contained in a tzinfo calendar and the
   ActiveSupport gem is loaded, then the result will be an ActiveSupport::TimeWithZone with the 
   proper tzid.
   
==== RDATE, and EXDATE properties (Occurrence Lists)

A calendar component which supports recurrence properties (e.g. Event) may have zero or more RDATE
and or EXDATE properties. Each RDATE/EXDATE property in turn specifies one or more occurrences to
be either added to or removed from the component's recurrence list. Each element of the list may be
either a DATE, a DATETIME, or a PERIOD, or the RFC 2445 string representation of one of these:

  event.rdate = "20090305"
  event.rdate = "20090305T120000"
  event.rdate = "20090305T120000/P1H30M"
  
It can also have multiple occurrences, specified as multiple parameters:

  event.rdate = "20090305T120000", "20090405T120000"
  event.rdate = DateTime.parse("12 December, 2005 3:00 pm"), DateTime.civil(2001, 3, 4, 15, 30, 0)
  

Multiple string values can be combined separated by commas:

   event.rdate = "20090305T120000,20090405T120000"


An occurrence list has one set of parameters, so only one timezone can be used, the timezone may
be set explicitly via the first argument.  If the first argument is a string, it is first split on
commas. Then if the first segment (up to the first comma if any) is not a valid RFC 2445
representation of a DATE, DATETIME, or PERIOD, then it will be used as the timezone for the
occurrence list. Otherwise the arguments must have the same time zone or an InvalidPropertyValue
error will be raised.
=== Parsing

RiCal can parse icalendar data from either a string or a Ruby io object.

The data may consist of one or more icalendar calendars, or one or more icalendar components (e.g.
one or more VEVENT, or VTODO objects.)

In either case the result will be an array of components.
==== From a string
	RiCal.parse_string <<ENDCAL
	BEGIN:VCALENDAR
	X-WR-TIMEZONE:America/New_York
	PRODID:-//Apple Inc.//iCal 3.0//EN
	CALSCALE:GREGORIAN
	X-WR-CALNAME:test
	VERSION:2.0
	X-WR-RELCALID:1884C7F8-BC8E-457F-94AC-297871967D5E
	X-APPLE-CALENDAR-COLOR:#2CA10B
	BEGIN:VTIMEZONE
	TZID:US/Eastern
	BEGIN:DAYLIGHT
	TZOFFSETFROM:-0500
	TZOFFSETTO:-0400
	DTSTART:20070311T020000
	RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU
	TZNAME:EDT
	END:DAYLIGHT
	BEGIN:STANDARD
	TZOFFSETFROM:-0400
	TZOFFSETTO:-0500
	DTSTART:20071104T020000
	RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU
	TZNAME:EST
	END:STANDARD
	END:VTIMEZONE
	BEGIN:VEVENT
	SEQUENCE:5
	TRANSP:OPAQUE
	UID:00481E53-9258-4EA7-9F8D-947D3041A3F2
	DTSTART;TZID=US/Eastern:20090224T090000
	DTSTAMP:20090225T000908Z
	SUMMARY:Test Event
	CREATED:20090225T000839Z
	DTEND;TZID=US/Eastern:20090224T100000
	RRULE:FREQ=DAILY;INTERVAL=1;UNTIL=20090228T045959Z
	END:VEVENT
	END:VCALENDAR
	ENDCAL

<b>Beware of the initial whitespace in the above example which is for rdoc formatting.</b> The parser does not strip initial whitespace from lines in the file and will fail.

As already stated the string argument may be a full icalendar format calendar, or just one or more subcomponents, e.g.

RiCal.parse_string("BEGIN:VEVENT\nDTSTART;TZID=US/Eastern:20090224T090000\nSUMMARY:Test Event\nDTEND;TZID=US/Eastern:20090224T100000\nRRULE:FREQ=DAILY;INTERVAL=1;UNTIL=20090228T045959Z\nEND:VEVENT")

==== From an Io
	File.open("path/to/file", "r") do |file|
	    components = RiCal.parse(file)
	end

=== Occurrence Enumeration

Event, Journal, and Todo components can have recurrences which are defined following the RFC 2445 specification.
A component with recurrences can enumerate those occurrences.

These components have common methods for enumeration which are defined in the RiCal::OccurrenceEnumerator module.

==== Obtaining an array of occurrences

To get an array of occurrences, Use the RiCal::OccurrenceEnumerator#occurrences method:

	event.occurrences

This method may fail with an argument error, if the component has an unbounded recurrence definition. This happens
when one or more of its RRULES don't have a COUNT, or UNTIL part.  This may be tested by using the RiCal::OccurrenceEnumerator#bounded? method.

In the case of unbounded components, you must either use the :count, or :before options of the RiCal::OccurrenceEnumerator#occurrences method:

	event.occurrences(:count => 10)

or

  event.occurrences(:before => Date.today >> 1)
  
Another option on the occurrences method is the :overlapping option, which takes an array of two Dates, Times or DateTimes which are expected to be in chronological order.  Only events which occur either partially or fully within the range given by the :overlapping option will be enumerated.

Alternately, you can use the RiCal::OccurrenceEnumerator#each method,
or another Enumerable method (RiCal::OccurrenceEnumerator includes Enumerable), and terminate when you wish by breaking out of the block.

	event.each do |event|
	   break if some_termination_condition
	   #....
	end

=== Unknown Components

Starting with version 0.8.0 RiCal will parse calendars and components which contain nonstandard components.

For example, there was a short-lived proposal to extend RFC2445 with a new VVENUE component which would hold structured information about the location of an event.  This proposal was never accepted and was withdrawn, but there is icalendar data in the wild which contains VVENUE components.

Prior to version 0.8.0, RiCal would raise an exception if unknown component types were encountered.  Starting with version 0.8.0 RiCal will 'parse' such components and create instances of NonStandard component to represent them.  Since the actual format of unknown components is not known by RiCal, the NonStandard component will simply save the data lines between the BEGIN:xxx and END:xxx lines, (where xxx is the non-standard component name, e.g. VVENUE).  If the calendar is re-exported the original lines will be replayed.

=== Change to treatment of X-properties

RFC2445 allows 'non-standard' or experimental properties which property-names beginning with X.  RiCal always supported parsing these.

The standard properties are specified as to how many times they can occur within a particular component.  For singly occurring properties RiCal returns a single property object, while for properties which can occur multiple times RiCal returns an array of property objects.

While implementing NonStandard properties, I realized that X-properties were being assumed to be singly occurring. But this isn't necessarily true.  So starting with 0.8.0 the X-properties are represented by an array of property objects.

THIS MAY BREAK SOME APPLICATIONS, but the adaptation should be easy.

== REQUIREMENTS:

* RiCal requires that an implementation of TZInfo::Timezone. This requirement may be satisfied by either the TzInfo gem,
or by a recent(>= 2.2) version of the ActiveSupport gem which is part of Ruby on Rails.

== INSTALL:

=== From RubyForge

    sudo gem install ri_cal
    
=== From github

==== As a Gem

    sudo gem install rubyredrick-ri_cal --source http://gems.github.com/
   
==== From source

    1. cd to a directory in which you want to install ri_cal as a subdirectory
    2. git clone http://github.com/rubyredrick/ri_cal  your_install_subdirectory
    3. cd your_install_directory
    4. rake spec
    5. rake install_gem



== LICENSE:

(The MIT License)

Copyright (c) 2009 Richard J. DeNatale

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.