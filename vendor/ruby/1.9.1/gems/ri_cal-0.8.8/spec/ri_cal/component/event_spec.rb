# encoding: utf-8
#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe RiCal::Component::Event do
  
  context "with change management properties" do
    it "should use zulu time for all change management datetime properties" do
      new_york_offset = Rational(-1, 6)
      cal = RiCal.Calendar
      event = RiCal::Component::Event.new(cal)
      event.dtstamp = result_time_in_zone(2010, 4, 1, 9, 23, 45, "America/New_York", new_york_offset)
      event.created = result_time_in_zone(2010, 4, 1, 9, 23, 45, "America/New_York", new_york_offset)
      event.last_modified = result_time_in_zone(2010, 4, 1, 12, 23, 45, "America/New_York", new_york_offset)
      event.to_s.should == "BEGIN:VEVENT
CREATED;VALUE=DATE-TIME:20100401T132345Z
DTSTAMP;VALUE=DATE-TIME:20100401T132345Z
LAST-MODIFIED;VALUE=DATE-TIME:20100401T162345Z
END:VEVENT
"
    end
  end
  
  context ".finish_time" do
    it "should be the end of the start day for an event with a date dtstart and no dtend or duration" do
      @it = RiCal.Event do |evt|
        evt.dtstart = "20090704"
      end
      @it.finish_time.should == DateTime.parse("20090704T235959")
    end
    
    it "should be the end of the end day for an event with a date dtstart and a dtend" do
      @it = RiCal.Event do |evt|
        evt.dtstart = "20090704"
        evt.dtend = "20090706"
      end
      @it.finish_time.should == DateTime.parse("20090706T235959")
    end
    
    it "should be the start time for an event with a datetime dtstart and no dtend or duration" do
      @it = RiCal.Event do |evt|
        evt.dtstart = "20090704T013000Z"
      end
      @it.finish_time.should == DateTime.parse("20090704T013000Z")
    end
    
    it "should be the end time for an event with a datetime dtend" do
      @it = RiCal.Event do |evt|
        evt.dtstart = "20090704"
        evt.dtend = "20090706T120000"
      end
      @it.finish_time.should == DateTime.parse("20090706T120000")
    end
    
    it "should be the end time for an event with a datetime dtstart and a duration" do
      @it = RiCal.Event do |evt|
        evt.dtstart = "20090704T120000Z"
        evt.duration = "PT1H30M"
      end
      @it.finish_time.should == DateTime.parse("20090704T133000Z")
    end
    
    it "should uset the  timezone of dtstart when event has a duration" do
      @it = RiCal.Event do |evt|
        evt.dtstart = "TZID=Australia/Sydney:20090712T200000"
        evt.duration = "PT1H"
      end
      @it.finish_time.should == DateTime.parse("2009-07-12T21:00:00+10:00")
    end
  end
  
  context ".before_range?" do
    context "with a Date dtstart and no dtend" do
      before(:each) do
        @it = RiCal.Event do |evt|
          evt.dtstart = "20090704"
        end
      end
      
      it "should be false if the range start is a date before the start date" do
        @it.before_range?([Date.parse("20090703"), :anything]).should_not be
      end
      
      it "should be false if the range start is the start date" do
        @it.before_range?([Date.parse("20090704"), :anything]).should_not be
      end
      
      it "should be true if the range start is a date after the start date" do
        @it.before_range?([Date.parse("20090705"), :anything]).should be
      end
    end

    context "with a Date dtstart and date dtend" do
      before(:each) do
        @it = RiCal.Event do |evt|
          evt.dtstart = "20090704"
          evt.dtend = "20090706"
        end
      end
      
      it "should be false if the range start is a date before the end date" do
        @it.before_range?([Date.parse("20090705"), :anything]).should_not be
      end
      
      it "should be false if the range start is the end date" do
        @it.before_range?([Date.parse("20090706"), :anything]).should_not be
      end
      
      it "should be true if the range start is a date after the end date" do
        @it.before_range?([Date.parse("20090707"), :anything]).should be
      end
    end
  end

  context "bug report from Noboyuki Tomizawa" do
    before(:each) do

      @it = RiCal.Calendar do |cal|
        cal.event do |event|
          event.description = "test"
          event.dtstart = "TZID=Asia/Tokyo:20090530T123000"
          event.dtend =   "TZID=Asia/Tokyo:20090530T123001"
        end
      end
    end
    
    it "should not fail" do
      lambda {@it.export}.should_not raise_error
    end
  end

  context "rdate property methods" do
    before(:each) do
      @event = RiCal.Event do
        rdate "20090101"
      end
    end

    context "#rdate=" do

      it "should accept a single Date and replace the existing rdate" do
        @event.rdate = Date.parse("20090102")
        @event.rdate.should == [[Date.parse("20090102")]]
      end

      it "should accept a single rfc2445 date format string and replace the existing rdate" do
        @event.rdate = "20090102"
        @event.rdate.should == [[Date.parse("20090102")]]
      end

      it "should accept a single DateTime and replace the existing rdate" do
        @event.rdate = DateTime.parse("20090102T012345")
        @event.rdate.should == [[DateTime.parse("20090102T012345")]]
      end

      it "should accept a single Time and replace the existing rdate" do
        ::RiCal::PropertyValue::DateTime.default_tzid = 'UTC'
        @event.rdate = Time.local(2009, 1, 2, 1, 23, 45)
        @event.rdate.should == [[result_time_in_zone(2009, 1, 2, 1, 23, 45, "UTC")]]
      end

      it "should accept a single rfc2445 date-time format string  and replace the existing rdate" do
        @event.rdate = "20090102T012345"
        @event.rdate.should == [[DateTime.parse("20090102T012345")]]
      end

      it "should accept a tzid prefixed rfc2445 date-time format string  and replace the existing rdate" do
        @event.rdate = "TZID=America/New_York:20090102T012345"
        @event.rdate.should == [[result_time_in_zone(2009, 1, 2, 1, 23, 45, "America/New_York")]]
      end

    end

  end

  context "comment property methods" do
    before(:each) do
      @event = RiCal.Event
      @event.comment = "Comment"
    end

    context "#comment=" do
      it "should result in a single comment for the event" do
        @event.comment.should == ["Comment"]
      end

      it "should replace existing comments" do
        @event.comment = "Replacement"
        @event.comment.should == ["Replacement"]
      end
    end

    context "#comments=" do
      it "should result in a multiple comments for the event replacing existing comments" do
        @event.comments = "New1", "New2"
        @event.comment.should == ["New1", "New2"]
      end
    end

    context "#add_comment" do
      it "should add a single comment" do
        @event.add_comment "New1"
        @event.comment.should == ["Comment", "New1"]
      end
    end

    context "#add_comments" do
      it "should add multiple comments" do
        @event.add_comments "New1", "New2"
        @event.comment.should == ["Comment", "New1", "New2"]
      end
    end

    context "#remove_comment" do
      it "should remove a single comment" do
        @event.add_comment "New1"
        @event.remove_comment "Comment"
        @event.comment.should == ["New1"]
      end
    end

    context "#remove_comments" do
      it "should remove multiple comments" do
        @event.add_comments "New1", "New2", "New3"
        @event.remove_comments "New2", "Comment"
        @event.comment.should == ["New1", "New3"]
      end
    end
  end

  context ".dtstart=" do
    before(:each) do
      @event = RiCal.Event
    end

    context "with a datetime only string" do
      before(:each) do
        @event.dtstart = "20090514T202400"
        @it = @event.dtstart
      end

      it "should interpret it as the correct date-time" do
        @it.should == DateTime.civil(2009, 5, 14, 20, 24, 00, Rational(0,24))
      end

      it "should interpret it as a floating date" do
        @it.tzid.should == :floating
      end
    end

    context "with a TZID and datetime string" do
      before(:each) do
        @event.dtstart = "TZID=America/New_York:20090514T202400"
        @it = @event.dtstart
      end

      it "should interpret it as the correct date-time" do
        @it.should == result_time_in_zone(2009, 5, 14, 20, 24, 00, "America/New_York")
      end

      it "should set the tzid to America/New_York" do
        @it.tzid.should == "America/New_York"
      end
    end

    context "with a zulu datetime only string" do
      before(:each) do
        @event.dtstart = "20090514T202400Z"
        @it = @event.dtstart
      end

      it "should interpret it as the correct date-time" do
        @it.should == DateTime.civil(2009, 5, 14, 20, 24, 00, Rational(0,24))
      end

      it "should set the tzid to UTC" do
        @it.tzid.should == "UTC"
      end
    end

    context "with a date string" do
      before(:each) do
        @event.dtstart = "20090514"
        @it = @event.dtstart
      end

      it "should interpret it as the correct date-time" do
        @it.should == Date.parse("14 May 2009")
      end
    end
  end

  context ".entity_name" do
    it "should be VEVENT" do
      RiCal::Component::Event.entity_name.should == "VEVENT"
    end
  end

  context "with an rrule" do
    before(:each) do
      @it = RiCal::Component::Event.parse_string("BEGIN:VEVENT\nRRULE:FREQ=DAILY\nEND:VEVENT").first
    end

    it "should have an array of rrules" do
      @it.rrule.should be_kind_of(Array)
    end
  end

  context ".start_time" do

    it "should be nil if there is no dtstart property" do
      RiCal.Event.start_time.should be_nil
    end

    it "should be the same as dtstart for a date time" do
      event = RiCal.Event {|e| e.dtstart = "20090525T151900"}
      event.start_time.should == DateTime.civil(2009,05,25,15,19,0,0)
    end

    it "should be the start of the day of dtstart for a date" do
      event = RiCal.Event {|e| e.dtstart = "20090525"}
      event.start_time.should == DateTime.civil(2009,05,25,0,0,0,0)
    end
  end

  context ".finish_time" do
    before(:each) do
      @event = RiCal.Event {|e| e.dtstart = "20090525T151900"}
    end

    context "with a given dtend" do
      it "should be the same as dtend for a date time" do
        @event.dtend = "20090525T161900"
        @event.finish_time.should == DateTime.civil(2009,05,25,16,19,0,0)
      end


    end

    context "with no dtend" do
      context "and a duration" do
        it "should be the dtstart plus the duration" do
          @event.duration = "+PT1H"
          @event.finish_time.should == DateTime.civil(2009,5,25,16,19,0,0)
        end
      end

      context "and no duration" do
        context "when the dtstart is not set" do
          before(:each) do
            @event.dtstart_property = nil
          end

          it "should be nil" do
            @event.finish_time.should be_nil
          end
        end
        context "when the dstart is a datetime" do
          # For cases where a "VEVENT" calendar component
          # specifies a "DTSTART" property with a DATE-TIME data type but no
          # "DTEND" property, the event ends on the same calendar date and time
          # of day specified by the "DTSTART" property. RFC 2445 p 53
          it "should be the same as start_time" do
            @event.finish_time.should == @event.start_time
          end
        end
        context "when the dtstart is a date" do
          # For cases where a "VEVENT" calendar component specifies a "DTSTART" property with a DATE data type
          # but no "DTEND" property, the events non-inclusive end is the end of the calendar date specified by
          # the "DTSTART" property. RFC 2445 p 53

          it "should be the end of the same day as start_time" do
            @event.dtstart = "20090525"
            @event.finish_time.should == DateTime.civil(2009,5,25,23,59,59,0)
          end
        end
      end
    end

  end

  context ".zulu_occurrence_range_start_time" do

    it "should be nil if there is no dtstart property" do
      RiCal.Event.zulu_occurrence_range_start_time.should be_nil
    end

    it "should be the utc equivalent of dtstart for a date time" do
      event = RiCal.Event {|e| e.dtstart = "TZID=America/New_York:20090525T151900"}
      event.zulu_occurrence_range_start_time.should == DateTime.civil(2009,05,25,19,19,0,0)
    end

    it "should be the utc time of the start of the day of dtstart in the earliest timezone for a date" do
      event = RiCal.Event {|e| e.dtstart = "20090525"}
      result = event.zulu_occurrence_range_start_time
      result.should == DateTime.civil(2009,05,24,12,0,0,0)
    end

    it "should be the utc time of the dtstart in the earliest timezone if dtstart is a floating datetime" do
      event = RiCal.Event {|e| e.dtstart = "20090525T151900"}
      event.zulu_occurrence_range_start_time.should == DateTime.civil(2009,05,25,3,19,0,0)
    end
  end

  context ".zulu_occurrence_range_finish_time" do
    before(:each) do
      @event = RiCal.Event {|e| e.dtstart = "TZID=America/New_York:20090525T151900"}
    end

    context "with a given dtend" do
      it "should be the utc equivalent of dtend if dtend is a date time" do
        @event.dtend = "TZID=America/New_York:20090525T161900"
        @event.zulu_occurrence_range_finish_time.should == DateTime.civil(2009,05,25, 20,19,0,0)
      end
    end

    context "with no dtend" do
      context "and a duration" do
        it "should be the dtstart plus the duration" do
          @event.duration = "+PT1H"
          @event.zulu_occurrence_range_finish_time.should == DateTime.civil(2009,5,25,20 ,19,0,0)
        end
      end

      context "and no duration" do
        context "when the dtstart is not set" do
          before(:each) do
            @event.dtstart_property = nil
          end

          it "should be nil" do
            @event.zulu_occurrence_range_finish_time.should be_nil
          end
        end

        context "when the dstart is a datetime" do

          it "should be the same as start_time" do
            @event.zulu_occurrence_range_finish_time.should == @event.zulu_occurrence_range_start_time
          end
        end
        
        context "when the dtstart is a date" do
          it "should be the utc of end of the same day as start_time in the westermost time zone" do
            @event.dtstart = "20090525"
            @event.zulu_occurrence_range_finish_time.should == DateTime.civil(2009,5,26,11,59,59,0)
          end
        end
      end
    end
  end

  context "description property" do
    before(:each) do
      @ical_desc = "posted by Joyce per Zan\\nASheville\\, Rayan's Restauratn\\, Biltm\n ore Square"
      @ruby_desc = "posted by Joyce per Zan\nASheville, Rayan's Restauratn, Biltmore Square"
      @it = RiCal::Component::Event.parse_string("BEGIN:VEVENT\nDESCRIPTION:#{@ical_desc}\nEND:VEVENT").first
    end

    it "should product the converted ruby value" do
      @it.description.should == @ruby_desc
    end

    it "should produce escaped text for ical" do
      @it.description = "This is a\nnew description, yes; it is"
      @it.description_property.value.should == 'This is a\nnew description\, yes\; it is'
    end

  end

  context "with both dtend and duration specified" do
    before(:each) do
      @it = RiCal::Component::Event.parse_string("BEGIN:VEVENT\nDTEND:19970903T190000Z\nDURATION:H1\nEND:VEVENT").first
    end

    it "should be invalid" do
      @it.should_not be_valid
    end
  end

  context "with a duration property" do
    before(:each) do
      @it = RiCal::Component::Event.parse_string("BEGIN:VEVENT\nDURATION:H1\nEND:VEVENT").first
    end

    it "should have a duration property" do
      @it.duration_property.should be
    end

    it "should have a duration of 1 Hour" do
      @it.duration_property.value.should == "H1"
    end

    it "should reset the duration property if the dtend property is set" do
      @it.dtend_property = "19970101T123456".to_ri_cal_date_time_value
      @it.duration_property.should be_nil
    end

    it "should reset the duration property if the dtend ruby value is set" do
      @it.dtend = "19970101"
      @it.duration_property.should == nil
    end
  end

  context "with a dtend property" do
    before(:each) do
      @it = RiCal::Component::Event.parse_string("BEGIN:VEVENT\nDTEND:19970903T190000Z\nEND:VEVENT").first
    end

    it "should have a duration property" do
      @it.dtend_property.should be
    end

    it "should reset the dtend property if the duration property is set" do
      @it.duration_property = "PT1H".to_ri_cal_duration_value
      @it.dtend_property.should be_nil
    end

    it "should reset the dtend property if the duration ruby value is set" do
      @it.duration = "PT1H".to_ri_cal_duration_value
      @it.dtend_property.should be_nil
    end
  end

  context "with a nested alarm component" do
    before(:each) do
      @it = RiCal::Component::Event.parse_string("BEGIN:VEVENT\nDTEND:19970903T190000Z\n\nBEGIN:VALARM\nEND:VALARM\nEND:VEVENT").first
    end

    it "should have one alarm" do
      @it.alarms.length.should == 1
    end

    it "which should be an Alarm component" do
      @it.alarms.first.should be_kind_of(RiCal::Component::Alarm)
    end
  end

  context ".export" do
    require 'rubygems'
    require 'tzinfo'

    def date_time_with_tzinfo_zone(date_time, timezone="America/New_York")
      date_time.dup.set_tzid(timezone)
    end

    # Undo the effects of RFC2445 line folding
    def unfold(string)
      string.gsub("\n ", "")
    end

    before(:each) do
      cal = RiCal.Calendar
      @it = RiCal::Component::Event.new(cal)
    end

    it "should cause a VTIMEZONE to be included for a dtstart with a local timezone" do
      @it.dtstart = date_time_with_tzinfo_zone(DateTime.parse("April 22, 2009 17:55"), "America/New_York")
      unfold(@it.export).should match(/BEGIN:VTIMEZONE\nTZID;X-RICAL-TZSOURCE=TZINFO:America\/New_York\n/)
    end

    it "should properly format dtstart with a UTC date-time" do
      @it.dtstart = DateTime.parse("April 22, 2009 1:23:45").set_tzid("UTC")
      unfold(@it.export).should match(/^DTSTART;VALUE=DATE-TIME:20090422T012345Z$/)
    end

    it "should properly format dtstart with a floating date-time" do
      @it.dtstart = DateTime.parse("April 22, 2009 1:23:45").with_floating_timezone
      unfold(@it.export).should match(/^DTSTART;VALUE=DATE-TIME:20090422T012345$/)
    end

    it "should properly format dtstart with a local time zone" do
      @it.dtstart = date_time_with_tzinfo_zone(DateTime.parse("April 22, 2009 17:55"), "America/New_York")
      unfold(@it.export).should match(/^DTSTART;TZID=America\/New_York;VALUE=DATE-TIME:20090422T175500$/)
    end

    it "should properly format dtstart with a date" do
      @it.dtstart = Date.parse("April 22, 2009")
      unfold(@it.export).should match(/^DTSTART;VALUE=DATE:20090422$/)
    end

    it "should properly fold on export when the description contains a carriage return" do
      @it.description = "Weather report looks nice, 80 degrees and partly cloudy, so following Michael's suggestion, let's meet at the food court at Crossroads:\n\rhttp://www.shopcrossroadsplaza.c...\n"
      export_string = @it.export
      export_string.should match(%r(^DESCRIPTION:Weather report looks nice\\, 80 degrees and partly cloudy\\, so$))
      export_string.should match(%r(^  following Michael's suggestion\\, let's meet at the food court at Crossr$))
      export_string.should match(%r(^ oads:\\nhttp://www\.shopcrossroadsplaza.c\.\.\.\\n$))
    end

    it "should properly fold on export when the description contains multi-byte UTF-8 Characters" do
      @it.description = "Juin 2009 <<Alliance Francaise Reunion>> lieu Café périferôl"
      export_string = @it.export
      export_string.should match(%r(^DESCRIPTION:Juin 2009 <<Alliance Francaise Reunion>> lieu Café périfer$))
      export_string.should match(%r(^ ôl$))
    end
  end

  if RiCal::TimeWithZone
    context "with ActiveSupport loaded" do

      context "an event with an timezoned exdate" do
        before(:each) do
          @old_timezone = Time.zone
          Time.zone = "America/New_York"
          @exception_date_time = Time.zone.local(2009, 5, 19, 11, 13)
           cal = RiCal.Calendar do |cal|
            cal.event do |event|
              event.add_exdate @exception_date_time
            end
          end
          @event = cal.events.first
        end

        after(:each) do
          Time.zone = @old_timezone
        end

        it "should pickup the timezone in the exdate property" do
          @event.exdate.first.first.tzid.should == "America/New_York"
        end

        it "should have the timezone in the ical representation of the exdate property" do
          @event.exdate_property.first.to_s.should match(%r{;TZID=America/New_York[:;]})
        end
      end

      context "An event in a non-tzinfo source calendar" do
              before(:each) do
                cals = RiCal.parse_string <<ENDCAL
BEGIN:VCALENDAR
X-WR-TIMEZONE:America/New_York
PRODID:-//Apple Inc.//iCal 3.0//EN
CALSCALE:GREGORIAN
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
          @event = cals.first.events.first
        end

        it "should produce a DateTime for dtstart" do
          @event.dtstart.should be_instance_of(DateTime)
        end
      end

      context "An event starting in Paris and ending in New York" do

        before(:each) do
          @start = Time.now.utc.in_time_zone("Europe/Paris")
          @finish = Time.now.utc.in_time_zone("America/New_York")
          cal = RiCal.Calendar do |ical|
            ical.event do |ievent|
              ievent.dtstart @start
              ievent.dtend   @finish
            end
          end
          @event = cal.events.first
        end

        it "should have the right time zone for dtstart" do
          @event.dtstart.tzid.should == "Europe/Paris"
        end

        it "should produce a TimeWithZone for dtstart" do
          @event.dtstart.should be_instance_of(RiCal::TimeWithZone)
        end

        # ActiveRecord::TimeWithZone doesn't implement == as expected
        it "should produce a dtstart which looks like the provided value" do
          @event.dtstart.to_s.should == @start.to_s
        end

        it "should have the right time zone for dtend" do
          @event.dtend.tzid.should == "America/New_York"
        end

        it "should produce a TimeWithZone for dtend" do
          @event.dtend.should be_instance_of(RiCal::TimeWithZone)
        end

        # ActiveRecord::TimeWithZone doesn't implement == as expected
        it "should produce a dtend which looks like the provided value" do
          @event.dtend.to_s.should == @finish.to_s
        end
      end
    end
  end

  context "An event with a floating start" do

    before(:each) do
      cal = RiCal.Calendar do |ical|
        ical.event do |ievent|
          ievent.dtstart "20090530T120000"
        end
      end
      @event = cal.events.first
    end

    it "should produce a DateTime for dtstart" do
      @event.dtstart.should be_instance_of(DateTime)
    end

    it "should have a floating dtstart" do
      @event.dtstart.should have_floating_timezone
    end
  end
end