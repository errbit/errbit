#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require 'rubygems'
require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe "an event with unneeded by parts" do
  before(:each) do
    rawdata = <<END_STR
BEGIN:VCALENDAR
PRODID:-//Google Inc//Google Calendar 70.9054//EN
VERSION:2.0
CALSCALE:GREGORIAN
METHOD:PUBLISH
X-WR-CALNAME:RICal teste
X-WR-TIMEZONE:America/Sao_Paulo
X-WR-CALDESC:
BEGIN:VTIMEZONE
TZID:America/Sao_Paulo
X-LIC-LOCATION:America/Sao_Paulo
BEGIN:DAYLIGHT
TZOFFSETFROM:-0300
TZOFFSETTO:-0200
TZNAME:BRST
DTSTART:19701018T000000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=3SU
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:-0300
TZOFFSETTO:-0300
TZNAME:BRT
DTSTART:19700215T000000
RRULE:FREQ=YEARLY;BYMONTH=2;BYDAY=3SU
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
DTSTART;VALUE=DATE:19400713
DTEND;VALUE=DATE:19400714
RRULE:FREQ=YEARLY;BYMONTH=7;BYMONTHDAY=13
DTSTAMP:20091109T161426Z
UID:CD0000008B9511D182D800C04FB1625DF48568F41595384496C2570C025DC032
CREATED:20090924T160743Z
DESCRIPTION: Description test 12
LAST-MODIFIED:20090924T160945Z
LOCATION: Location test 12
SEQUENCE:0
STATUS:CONFIRMED
SUMMARY: Event test 12
TRANSP:TRANSPARENT
END:VEVENT
END:VCALENDAR
END_STR
    @cal = RiCal.parse_string(rawdata).first
    @event = @cal.events.first
  end
  
  it "should enumerate 10 events from July 13, 1940 to July 13, 1949 when count is 10" do
    @event.occurrences(:count => 10).map {|occurrence| occurrence.dtstart}.should == (0..9).map {|y|
      Date.parse("July 13, #{1940+y}")
      }
  end
  
  # describe "with a dtstart outside the recurrence rule" do
  #   before(:each) do
  #     @event.dtstart = Date.parse("July 12, 1940")
  #   end
  #   
  #   it "should enumerate 10 events first July 12, 1940, July 13, 1940, July 13, 1941 when count is 3" do
  #     @event.occurrences(:count => 3).map {|occurrence| occurrence.dtstart.to_s}.should == [
  #       Date.parse("July 12, 1940").to_s,
  #       Date.parse("July 13, 1940").to_s,
  #       Date.parse("July 13, 1941").to_s
  #     ]
  #       
  #   end
  # 
  # end
  
end