#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe "http://rick_denatale.lighthouseapp.com/projects/30941/tickets/17" do
  it "should parse this" do
    RiCal.parse_string(<<-ENDCAL)
BEGIN:VCALENDAR
PRODID:-//Google Inc//Google Calendar 70.9054//EN
VERSION:2.0
CALSCALE:GREGORIAN
METHOD:PUBLISH
X-WR-CALNAME:Australian Tech Events
X-WR-TIMEZONE:Australia/Sydney
X-WR-CALDESC:TO ADD EVENTS INVITE THIS ADDRESS\;\npf44opfb12hherild7h2pl11b
 4@group.calendar.google.com\n\nThis is a public calendar to know what's com
 ing up all around the country in the technology industry.\n\nIncludes digit
 al\, internet\, web\, enterprise\, software\, hardware\, and it's various f
 lavours. \n\nFeel free to add real events. Keep it real.
BEGIN:VTIMEZONE
TZID:Australia/Perth
X-LIC-LOCATION:Australia/Perth
BEGIN:STANDARD
TZOFFSETFROM:+0800
TZOFFSETTO:+0800
TZNAME:WST
DTSTART:19700101T000000
END:STANDARD
END:VTIMEZONE
BEGIN:VTIMEZONE
TZID:Australia/Sydney
X-LIC-LOCATION:Australia/Sydney
BEGIN:STANDARD
TZOFFSETFROM:+1100
TZOFFSETTO:+1000
TZNAME:EST
DTSTART:19700405T030000
RRULE:FREQ=YEARLY;BYMONTH=4;BYDAY=1SU
END:STANDARD
BEGIN:DAYLIGHT
TZOFFSETFROM:+1000
TZOFFSETTO:+1100
TZNAME:EST
DTSTART:19701004T020000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=1SU
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VTIMEZONE
TZID:Australia/Brisbane
X-LIC-LOCATION:Australia/Brisbane
BEGIN:STANDARD
TZOFFSETFROM:+1000
TZOFFSETTO:+1000
TZNAME:EST
DTSTART:19700101T000000
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
DTSTART:20091110T080000Z
DTEND:20091110T100000Z
DTSTAMP:20090720T133540Z
UID:9357CC6B-C4BF-4797-AC5F-83E47C3FDA9E
URL:thehive.org.au
CLASS:PUBLIC
CREATED:20090713T123838Z
DESCRIPTION:check the website for details
LAST-MODIFIED:20090713T123838Z
LOCATION:Melbourne
SEQUENCE:1
STATUS:CONFIRMED
SUMMARY:The Hive MELBOURNE
TRANSP:OPAQUE
BEGIN:VALARM
ACTION:AUDIO
TRIGGER:-PT5M
X-WR-ALARMUID:F92A055A-2CD9-4FB2-A22A-BD4834ACEE96
ATTACH;VALUE=URI:Basso
END:VALARM
END:VEVENT
END:VCALENDAR
ENDCAL
  end
end

describe "http://rick_denatale.lighthouseapp.com/projects/30941/tickets/18" do
  it "should handle a subcomponent" do
    event = RiCal.Event do |evt|
      evt.alarm do |alarm|
        alarm.trigger = "-PT5M"
        alarm.action = 'AUDIO'
      end
    end

    lambda {event.export}.should_not raise_error
  end
end

describe "http://rick_denatale.lighthouseapp.com/projects/30941/tickets/19" do
  before(:each) do
    cals = RiCal.parse_string(<<-ENDCAL)
BEGIN:VCALENDAR
METHOD:REQUEST
PRODID:Microsoft CDO for Microsoft Exchange
VERSION:2.0
BEGIN:VTIMEZONE
TZID:(GMT-05.00) Eastern Time (US & Canada)
X-MICROSOFT-CDO-TZID:10
BEGIN:STANDARD
DTSTART:20010101T020000
TZOFFSETFROM:-0400
TZOFFSETTO:-0500
RRULE:FREQ=YEARLY;WKST=MO;INTERVAL=1;BYMONTH=11;BYDAY=1SU
END:STANDARD
BEGIN:DAYLIGHT
DTSTART:20010101T020000
TZOFFSETFROM:-0500
TZOFFSETTO:-0400
RRULE:FREQ=YEARLY;WKST=MO;INTERVAL=1;BYMONTH=3;BYDAY=2SU
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
DTSTAMP:20090724T143205Z
DTSTART;TZID="(GMT-05.00) Eastern Time (US & Canada)":20090804T120000
SUMMARY:FW: ALL HANDS MEETING
DTEND;TZID="(GMT-05.00) Eastern Time (US & Canada)":20090804T133000
DESCRIPTION:Some event
END:VEVENT
END:VCALENDAR
ENDCAL

    @event = cals.first.events.first
  end

  it "not raise an error accessing DTSTART" do
    lambda {@event.dtstart}.should_not raise_error
  end
end

describe "freebusy problem" do
  before(:each) do
    cal = RiCal.parse_string(<<ENDCAL)
BEGIN:VCALENDAR
METHOD:PUBLISH
VERSION:2.0
PRODID:Zimbra-Calendar-Provider
BEGIN:VFREEBUSY
ORGANIZER:mailto:bj-wagoner@wiu.edu
DTSTAMP:20090805T200417Z
DTSTART:20090705T200417Z
DTEND:20091006T200417Z
URL:https://zimbra9.wiu.edu/service/home/bjw101/calendar.ifb?null
FREEBUSY;FBTYPE=BUSY:20090705T200417Z/20090707T050000Z
FREEBUSY;FBTYPE=BUSY-TENTATIVE:20090711T050000Z/20090712T050000Z
END:VFREEBUSY
END:VCALENDAR
ENDCAL
  @free_busy = cal.first.freebusys.first
  end

  it "should have two periods" do
    @free_busy.freebusy.map {|fb| fb.to_s}.should == [
      ";FBTYPE=BUSY:20090705T200417Z/20090707T050000Z",
      ";FBTYPE=BUSY-TENTATIVE:20090711T050000Z/20090712T050000Z"
      ]
  end
end

describe "a calendar including vvenue" do
  before(:each) do
    @cal_string = <<ENDCAL
BEGIN:VCALENDAR
VERSION:2.0
X-WR-CALNAME:Upcoming Event: Film in the Park
PRODID:-//Upcoming.org/Upcoming ICS//EN
CALSCALE:GREGORIAN
METHOD:PUBLISH
BEGIN:VEVENT
DTSTART:20090807T201500
DTEND:20090807T220000
RRULE:FREQ=DAILY;INTERVAL=1;UNTIL=20090822T000000
GEO:-104.997;39.546
TRANSP:TRANSPARENT
SUMMARY:Film in the Park
DESCRIPTION: [Full details at http://upcoming.yahoo.com/event/3082410/ ] Plan to join the HRCA family summer tradition! Bring a blanket and enjoy great FREE family movies! Mark the dates now!
URL;VALUE=URI:http://upcoming.yahoo.com/event/3082410/
UID:http://upcoming.yahoo.com/event/3082410/
DTSTAMP:20090716T103006
LAST-UPDATED:20090716T103006
CATEGORIES:Family
ORGANIZER;CN=mepling95:X-ADDR:http://upcoming.yahoo.com/user/637615/
LOCATION;VENUE-UID="http://upcoming.yahoo.com/venue/130821/":Civic Green Park @ 9370 Ridgeline Boulevard\, Highlands Ranch\, Colorado 80126 US
END:VEVENT
BEGIN:VVENUE
X-VVENUE-INFO:http://evdb.com/docs/ical-venue/drft-norris-ical-venue.html
NAME:Civic Green Park
ADDRESS:9370 Ridgeline Boulevard
CITY:Highlands Ranch
REGION;X-ABBREV=co:Colorado
COUNTRY;X-ABBREV=us:United States
POSTALCODE:80126
GEO:39.546;-104.997
URL;X-LABEL=Venue Info:http://www.hrmafestival.org
END:VVENUE
END:VCALENDAR
ENDCAL

  @venue_str = <<ENDVENUE
BEGIN:VVENUE
X-VVENUE-INFO:http://evdb.com/docs/ical-venue/drft-norris-ical-venue.html
NAME:Civic Green Park
ADDRESS:9370 Ridgeline Boulevard
CITY:Highlands Ranch
REGION;X-ABBREV=co:Colorado
COUNTRY;X-ABBREV=us:United States
POSTALCODE:80126
GEO:39.546;-104.997
URL;X-LABEL=Venue Info:http://www.hrmafestival.org
END:VVENUE
ENDVENUE
  end

  it "should parse without error" do
    lambda {RiCal.parse_string(@cal_string)}.should_not raise_error
  end
  
  it "should export correctly" do
    export = RiCal.parse_string(@cal_string).first.export
    export.should include(@venue_str)
  end
end

context "ticket #23" do
  describe "RecurrenceRule" do
    it "should convert the rrule string to a hash" do
      rrule = RiCal::PropertyValue::RecurrenceRule.convert(nil, 'INTERVAL=2;FREQ=WEEKLY;BYDAY=TH,TU')
      rrule.to_options_hash.should == {:freq => 'WEEKLY', :byday => %w{TH TU}, :interval => 2}
    end
  end
end

context "ticket #26" do
  context "Date property" do
    it "should handle for_parent" do
      lambda {
      RiCal::PropertyValue::Date.convert(:foo, Date.parse("20090927")).for_parent(:bar)}.should_not raise_error
    end
  end
end

context "ticket 29:supress-x-rical-tzsource-when-not-relevant" do
  it "should parse its own output" do
    cal_string = %Q(BEGIN:VCALENDAR
PRODID:-//Google Inc//Google Calendar 70.9054//EN
BEGIN:VEVENT
DTSTART:20100610T100000
DTEND:20100610T110000
END:VEVENT
END:VCALENDAR)
    lambda {RiCal.parse_string(RiCal.parse_string(cal_string).first.to_s)}.should_not raise_error
  end
end

context "X-properties" do
  it "should round-trip the X-WR-CALNAME property" do
    cal_string = %Q(BEGIN:VCALENDAR
PRODID:-//Markthisdate.com\,0.7
VERSION:2.0
CALSCALE:GREGORIAN
METHOD:PUBLISH
X-WR-CALNAME: AFC Ajax Eredivisie wedstrijden 2010 - 2011
END:VCALENDAR)
      cal = RiCal.parse_string(cal_string).first
      cal.x_wr_calname.first.should == " AFC Ajax Eredivisie wedstrijden 2010 - 2011"
    end
end

