#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. spec_helper])
require 'tzinfo'

describe RiCal::Component do

  context "building blocks" do

    context "building an empty calendar" do
      before(:each) do
        @it = RiCal.Calendar.to_s
      end

      it "should have the default prodid" do
        @it.should match(%r{^PRODID;X-RICAL-TZSOURCE=TZINFO:-//com.denhaven2/NONSGML ri_cal gem//EN$})
      end

      it "should have the default calscale" do
        @it.should match(%r{^CALSCALE:GREGORIAN$})
      end

      it "should have the default icalendar version" do
        @it.should match(%r{^VERSION:2\.0$})
      end
    end

    context "building a calendar with time zones" do
      it 'should allow specifying the time zone identifier' do
        event = RiCal.Event do
          dtstart     DateTime.parse("Feb 20, 1962 14:47:39").set_tzid('US/Pacific')
        end
        event.dtstart_property.should == dt_prop(DateTime.parse("Feb 20, 1962 14:47:39"), tzid = 'US/Pacific')
      end

      context "adding an exception date" do
        
        before(:each) do
          @cal =  RiCal.Calendar do
            event do
              add_exdate 'US/Eastern', "19620220T144739"
            end
          end
          @event = @cal.events.first
          @prop = @event.exdate_property.first
        end

        it "should produce an OccurrenceList for the property" do
          @prop.should be_instance_of(RiCal::PropertyValue::OccurrenceList)
        end

        it "should have a property with the right ical representation" do
          @prop.to_s.should == ";TZID=US/Eastern:19620220T144739"
        end
        
        context "its ruby_value" do
          it "should have the right value" do
            @prop.ruby_value.should == [DateTime.civil(1962, 2, 20, 14, 47, 39, Rational(-5, 24))]
          end
          
          it "should have the right tzid" do
            @prop.ruby_value.first.tzid.should == "US/Eastern"
          end
        end
      end
    end

    context "with a block with 1 parameter" do
      before(:each) do
        @it = RiCal.Event do |event|
          event.description = "MA-6 First US Manned Spaceflight"
          event.dtstart = DateTime.parse("Feb 20, 1962 14:47:39")
          event.dtend = DateTime.parse("Feb 20, 1962 19:43:02")
          event.location = "Cape Canaveral"
          event.add_attendee "john.glenn@nasa.gov"
          event.alarm do
            description "Segment 51"
          end
          event.alarm do |alarm|
            alarm.description = "Second alarm"
          end
        end
      end

      it "should have the right description" do
        @it.description.should == "MA-6 First US Manned Spaceflight"
      end
      it "should have the right dtstart" do
        @it.dtstart.should == DateTime.parse("Feb 20, 1962 14:47:39")
      end

      it "should have a zulu time dtstart property" do
        @it.dtstart_property.tzid.should == "UTC"
      end

      it "should have the right dtend" do
        @it.dtend.should == DateTime.parse("Feb 20, 1962 19:43:02")
      end

      it "should have a zulu time dtend property" do
        @it.dtend_property.tzid.should == "UTC"
      end

      it "should have the right location" do
        @it.location.should == "Cape Canaveral"
      end

      it "should have the right attendee" do
        @it.attendee.should include("john.glenn@nasa.gov")
      end

      it "should have 2 alarms" do
        @it.alarms.length.should == 2
      end

      it ".the alarms should have the right description" do
        @it.alarms.first.description.should == "Segment 51"
        @it.alarms.last.description.should == "Second alarm"
      end
    end

    context "building an event for MA-6" do
      before(:each) do
        @it = RiCal.Event do
          description "MA-6 First US Manned Spaceflight"
          dtstart     DateTime.parse("Feb 20, 1962 14:47:39")
          dtend       DateTime.parse("Feb 20, 1962 19:43:02")
          location    "Cape Canaveral"
          add_attendee "john.glenn@nasa.gov"
          alarm do
            description "Segment 51"
          end
        end
      end

      it "should have the right description" do
        @it.description.should == "MA-6 First US Manned Spaceflight"
      end

      it "should have the right dtstart" do
        @it.dtstart.should == DateTime.parse("Feb 20, 1962 14:47:39")
      end

      it "should have a zulu time dtstart property" do
        @it.dtstart_property.tzid.should == "UTC"
      end

      it "should have the right dtend" do
        @it.dtend.should == DateTime.parse("Feb 20, 1962 19:43:02")
      end

      it "should have a zulu time dtend property" do
        @it.dtend_property.tzid.should == "UTC"
      end

      it "should have the right location" do
        @it.location.should == "Cape Canaveral"
      end

      it "should have the right attendee" do
        @it.attendee.should include("john.glenn@nasa.gov")
      end

      it "should have 1 alarm" do
        @it.alarms.length.should == 1
      end

      it "should have an alarm with the right description" do
        @it.alarms.first.description.should == "Segment 51"
      end
    end

    context "building a complex calendar" do

      before(:each) do
        @it = RiCal.Calendar do
          add_x_property 'x_wr_calname', 'My Personal Calendar', true
          event do
            summary     'A Recurring Event'
            description "This is some really long note content. It should be appropriately folded in the generated file.\nCarriage returns should work, too."
            dtstart     DateTime.parse('Feb 20, 2009 20:30:00')
            dtend       DateTime.parse('Feb 20, 2009 21:30:00')
            location    'North Carolina'
            dtstamp     Time.now
            rrule       :freq => 'daily', :interval => 1
          end
        end
      end

      it 'should have an x_wr_calname property with the value "My Personal Calendar"' do
        @it.x_wr_calname.first.should == "My Personal Calendar"
      end

      context "event with a long description and a dsl built recurence rule" do
        before(:each) do
          @cal = @it
          @it = @cal.events.first
        end

        context "its description" do
          it "should pass through correctly" do
           @it.description.should == "This is some really long note content. It should be appropriately folded in the generated file.\nCarriage returns should work, too."
          end
        end

        context "its rrule" do

          it "should have a 1 rrule" do
            @it.rrule.length.should == 1
          end

          it "should have the right rrule" do
            @it.rrule.first.should == "FREQ=DAILY"
          end

          it "should have the right rrule hash" do
            @it.rrule_property.first.to_options_hash.should == {:freq => 'DAILY', :interval => 1}
          end
        end
      end
    end

  end
end