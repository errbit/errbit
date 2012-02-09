#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require 'rubygems'
require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe "RiCal TimeZone problem" do
  it "should keep the original calendar timezone intact" do
    original_calendar = RiCal.parse_string(original_calendar_contents).first
    puts "*"*40
    puts original_calendar
    puts "*"*40
    reply_calendar = reply original_calendar
    #reply_calendar = RiCal.parse_string(reply_calendar_contents).first
    puts reply_calendar
    puts "*"*40

    original_event = original_calendar.events.first
    reply_event = reply_calendar.events.first
    reply_event.start_time.to_s.should == original_event.start_time.to_s
  end
end

private

# This is the calendar contents generated when we send the message >>#reply to the original calendar.
def reply_calendar_contents
  "BEGIN:VCALENDAR
PRODID;X-RICAL-TZSOURCE=TZINFO:-//com.denhaven2/NONSGML ri_cal gem//EN
CALSCALE:GREGORIAN
VERSION:2.0
METHOD:REPLY
BEGIN:VTIMEZONE
TZID;X-RICAL-TZSOURCE=TZINFO:America/Argentina/Buenos_Aires
BEGIN:STANDARD
DTSTART:20090314T230000
RDATE:20090314T230000
TZOFFSETFROM:-0200
TZOFFSETTO:-0300
TZNAME:ART
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
CREATED;VALUE=DATE-TIME:20091217T155557Z
DTEND;TZID=America/Argentina/Buenos_Aires;VALUE=DATE-TIME:20091227T010000
STATUS:CONFIRMED
LAST-MODIFIED;TZID=America/Argentina/Buenos_Aires;VALUE=DATE-TIME:2009121
 7T173400
DTSTART;TZID=America/Argentina/Buenos_Aires;VALUE=DATE-TIME:20091227T0000
 00
ATTENDEE;CN=PoketyPoke;PARTSTAT=ACCEPTED;ROLE=REQ-PARTICIPANT:barbarazopp
 o@gmail.com
UID:1693CA3B-C528-4E5A-87FB-CDFAEC0EC662
ORGANIZER:mailto:nasif.lucas@gmail.com
DESCRIPTION:
SUMMARY:testing.. Event
SEQUENCE:3
LOCATION:
END:VEVENT
END:VCALENDAR".strip
end

def original_calendar_contents
  "BEGIN:VCALENDAR\nPRODID:-//Apple Inc.//iCal 4.0.1//EN\nCALSCALE:GREGORIAN\nVERSION:2.0\nMETHOD:REQUEST\nBEGIN:VEVENT\nTRANSP:TRANSPARENT\nDTSTAMP;VALUE=DATE-TIME:20091217T155800Z\nCREATED;VALUE=DATE-TIME:20091217T155557Z\nDTEND;TZID=America/Argentina/Buenos_Aires;VALUE=DATE-TIME:20091227T010000\nDTSTART;TZID=America/Argentina/Buenos_Aires;VALUE=DATE-TIME:20091227T0000\n 00\nATTENDEE;CN=Lucas Nasif;CUTYPE=INDIVIDUAL;PARTSTAT=ACCEPTED:mailto:nasif.\n lucas@gmail.com\nATTENDEE;CN=barbarazoppo@gmail.com;CUTYPE=INDIVIDUAL;EMAIL=barbarazoppo@g\n mail.com;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT;RSVP=TRUE:mailto:bar\n barazoppo@gmail.com\nUID:1693CA3B-C528-4E5A-87FB-CDFAEC0EC662\nORGANIZER;CN=Lucas Nasif:mailto:nasif.lucas@gmail.com\nSUMMARY:testing.. Event\nSEQUENCE:3\nEND:VEVENT\nBEGIN:VTIMEZONE\nTZID:America/Argentina/Buenos_Aires\nBEGIN:STANDARD\nTZOFFSETTO:-0300\nDTSTART;VALUE=DATE-TIME:20080316T000000\nRRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=3SU\nTZOFFSETFROM:-0200\nTZNAME:GMT-03:00\nEND:STANDARD\nBEGIN:DAYLIGHT\nTZOFFSETTO:-0200\nDTSTART;VALUE=DATE-TIME:20081019T000000\nRRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=3SU\nTZOFFSETFROM:-0300\nTZNAME:GMT-02:00\nEND:DAYLIGHT\nEND:VTIMEZONE\nEND:VCALENDAR\n".strip
end

def reply(original_calendar)
  icalendar = RiCal.Calendar do | calendar |

    calendar.icalendar_method = "REPLY"
    calendar.default_tzid = original_calendar.default_tzid

    calendar.event do | event |

      original_event = original_calendar.events.first
      event.created = original_event.created
      event.dtstart = original_event.start_time
      event.dtend = original_event.finish_time
      event.organizer = original_event.organizer
      event.location = original_event.location.to_s
      event.uid_property = original_event.uid_property

      options = {'ROLE' => 'REQ-PARTICIPANT',
                 'PARTSTAT' => 'ACCEPTED',
                 'CN' => 'SomeName...'}

      attendee_property = RiCal::PropertyValue::CalAddress.new(nil,
                                                               :value => @attendant,
                                                               :params => options)

      event.attendee_property = attendee_property
      event.description = original_event.description.to_s
      event.summary = original_event.summary.to_s

      event.sequence_property = original_event.sequence_property
      event.status = "CONFIRMED"
      event.last_modified = DateTime.parse(Time.now.to_s)
    end
  end
  icalendar
end