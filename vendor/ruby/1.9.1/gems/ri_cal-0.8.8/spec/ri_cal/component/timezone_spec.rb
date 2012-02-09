#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])
require 'tzinfo'

describe RiCal::Component::Timezone do

  context ".entity_name" do
    it "should be VTIMEZONE" do
      RiCal::Component::Timezone.entity_name.should == "VTIMEZONE"
    end
  end

  context "for a Timezone with no DST periods" do
    before(:each) do
      @it = RiCal.parse_string rectify_ical(<<-'ENDCAL')
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
      ENDCAL
      @it = @it.first
    end

    context ".periods_for_local" do
      it "should return a single period" do
        @it.periods_for_local(DateTime.parse("20090530T100000")).length.should == 1
      end
    end
  end

  context "from an iCal.app calendar for America/New_York starting March 11 2007" do
    before(:each) do
      @it = RiCal.parse_string rectify_ical(<<-'ENDCAL')
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
      ENDCAL
      @it = @it.first
    end

    it "should be a Timezone" do
      @it.should be_kind_of(RiCal::Component::Timezone)
    end

    context ".local_to_utc" do
      it "should produce 2/27/2009 18:00 UTC for 2/27/2009 13:00" do
        expected = RiCal::PropertyValue::DateTime.new(nil, :value => "20090227T1800Z" )
        @it.local_to_utc(DateTime.parse("Feb 27, 2009 13:00")).should == expected
      end
    end

    context ".utc_to_local" do
      it "should produce 2/27/2009 13:00 EST for 2/27/2009 18:00 UTC" do
        expected = RiCal::PropertyValue::DateTime.new(nil, :params => {'TZID' => 'US/Eastern'}, :value => "20090227T1300" )
        @it.utc_to_local(DateTime.parse("Feb 27, 2009 18:00")).should == expected
      end
    end

    context ".period_for_local" do
      it "should raise TZInfo::PeriodNotFound for an invalid local time, e.g. Mar 8, 2009 2:30" do
        lambda {@it.period_for_local(DateTime.parse("Mar 8, 2009 2:30"))}.should raise_error(TZInfo::PeriodNotFound)
      end

      context "for an ambiguous local time , e.g. Nov 1, 2009 2:00" do
        context "lacking a dst parameter or block" do
          it "should raise TZInfo::AmbiguousTime" do
            lambda {@it.period_for_local(DateTime.parse("Nov 1, 2009 2:00"))}.should raise_error(TZInfo::AmbiguousTime)
          end
        end

        context "with a dst parameter" do
          it "should return a dst period if the dst parameter is true" do
            @it.period_for_local(DateTime.parse("Nov 1, 2009 2:00"), true).should be_dst
          end

          it "should return a std period if the dst parameter is false" do
            @it.period_for_local(DateTime.parse("Nov 1, 2009 2:00"), false).should_not be_dst
          end
        end

        context "with a block" do
          it "should return a period if the block returns a TimezonePeriod" do
            mock_period = ::RiCal::Component::Timezone::TimezonePeriod.new(nil)
            @it.period_for_local(DateTime.parse("Nov 1, 2009 2:00")) { |results| mock_period}.should == mock_period
          end

          it "should return a period if the block returns a single element array" do
            mock_period = :foo
            @it.period_for_local(DateTime.parse("Nov 1, 2009 2:00")) { |results| [ mock_period]}.should == mock_period
          end

          it "should raise TZInfo::PeriodNotFound if the block returns a multi-element array" do
            lambda {
              @it.period_for_local(DateTime.parse("Mar 8, 2009 2:30")) {|results| [1,2]}}.should raise_error(TZInfo::PeriodNotFound)
            end
          end
        end
      end

    context ".periods_for_local" do
      context "for the date on which DST begins springing ahead e.g. Mar 8, 2009" do
        it "should return a 1 element array for 1 second before the transition time" do
          @it.periods_for_local(DateTime.parse("Mar 8, 2009 1:59:59")).length.should == 1
        end

        it "should return an empty array for the transition time" do
          @it.periods_for_local(DateTime.parse("Mar 8, 2009 2:00:00")).should == []
        end

        it "should return an empty array for 1 second after the transition time" do
          @it.periods_for_local(DateTime.parse("Mar 8, 2009 2:00:01")).should == []
        end

        it "should return an empty array for 1 second before the spring ahead time" do
          @it.periods_for_local(DateTime.parse("Mar 8, 2009 2:59:59")).should == []
        end

        it "should return a 1 element array for the spring ahead time" do
          @it.periods_for_local(DateTime.parse("Mar 8, 2009 3:00:00")).length.should == 1
        end
      end

      context "for the date on which DST ends falling back e.g. Nov 11, 2009" do
        it "should return a 1 element array for 1 second before the transition time" do
          @it.periods_for_local(DateTime.parse("Nov 1, 2009 1:59:59")).length.should == 1
        end

        it "should return a 2 element array for the transition time" do
          @it.periods_for_local(DateTime.parse("Nov 1, 2009 2:00:00")).length.should == 2
        end

        it "should return a 2 element array for 1 second after the transition time" do
          @it.periods_for_local(DateTime.parse("Nov 1, 2009 2:00:01")).length.should == 2
        end

        it "should return a 2 element array for 59 minutes and 59 seconds after the transition time" do
          @it.periods_for_local(DateTime.parse("Nov 1, 2009 2:59:59")).length.should == 2
        end

        it "should return a 2 element array for 1 hour after the transition time" do
          @it.periods_for_local(DateTime.parse("Nov 1, 2009 3:00:00")).length.should == 2
        end

        it "should return a 2 element array for 1 hour and 1 second after the transition time" do
          @it.periods_for_local(DateTime.parse("Nov 1, 2009 3:00:01")).length.should == 2
        end
      end
    end
  end

  context "Bug report from paulsm" do
    before(:each) do
      cals = RiCal.parse_string rectify_ical(<<-'ENDCAL')
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
      @event = cals.first.events.first
    end
  
    context "the events dtstart" do
      it "should be the right DateTime" do
        @event.dtstart.should == DateTime.civil(2009, 2, 24, 9, 0, 0, Rational(-5, 24))
      end
  
      it "should have the right tzid" do
        @event.dtstart.tzid.should == "US/Eastern"
      end
    end
  
    context "the events dtend" do
      it "should be the right DateTime" do
        @event.dtend.should == DateTime.civil(2009, 2, 24, 10, 0, 0, Rational(-5, 24))
      end
  
      it "should have the right tzid" do
        @event.dtend.tzid.should == "US/Eastern"
      end
    end
  end
end
