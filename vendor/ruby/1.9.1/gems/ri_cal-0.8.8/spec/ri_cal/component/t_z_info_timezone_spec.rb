#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])
# Uncomment the next two lines to run this spec in textmate
# require 'rubygems'
# require 'tzinfo'

describe RiCal::Component::TZInfoTimezone do

  it "should produce an rfc representation" do
    tz = RiCal::Component::TZInfoTimezone.new(TZInfo::Timezone.get("America/New_York"))
    local_first = DateTime.parse("Apr 10, 2007")
    local_last = DateTime.parse("Apr 6, 2008")
    utc_first = tz.local_to_utc(local_first)
    utc_last = tz.local_to_utc(local_last)
    rez = tz.to_rfc2445_string(utc_first, utc_last)
    rez.should == <<-ENDDATA
BEGIN:VTIMEZONE
TZID;X-RICAL-TZSOURCE=TZINFO:America/New_York
BEGIN:DAYLIGHT
DTSTART:20070311T020000
RDATE:20070311T020000
RDATE:20080309T020000
TZOFFSETFROM:-0500
TZOFFSETTO:-0400
TZNAME:EDT
END:DAYLIGHT
BEGIN:STANDARD
DTSTART:20071104T020000
RDATE:20071104T020000
TZOFFSETFROM:-0400
TZOFFSETTO:-0500
TZNAME:EST
END:STANDARD
END:VTIMEZONE
ENDDATA
  end

  TZInfo::Timezone.all_identifiers.each do |tz|
    context "TZInfo timezone #{tz}" do
      before(:each) do
        @calendar = RiCal.Calendar do |cal|
          cal.event do |event|
            event.description = "test"
            event.dtstart = "TZID=#{tz}:20090530T123000"
            event.dtend =   "TZID=#{tz}:20090530T123001"
          end
        end
      end
      it "should be allowed as a tzid" do
        lambda {@calendar.export}.should_not raise_error
      end
      unless tz == "UTC"
        it "should produce at least one period in the VTIMEZONE" do
          @calendar.export.should match(/BEGIN:(STANDARD|DAYLIGHT)/)
        end
      end
    end
  end
end