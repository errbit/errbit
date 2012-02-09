#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe RiCal::PropertyValue::OccurrenceList do

  context ".convert method" do
    context "with a single datetime" do
      before(:each) do
        @it = RiCal::PropertyValue::OccurrenceList.convert(nil, DateTime.parse("5 May 2009, 9:32 am"))
      end

      it "should produce the right ical representation" do
        @it.to_s.should == ":20090505T093200Z"
      end

      it "should have the right ruby value" do
        @it.ruby_value.should == [DateTime.parse("5 May 2009, 9:32 am")]
      end

      it "should have the right elements" do
        @it.send(:elements).should == [RiCal::PropertyValue::DateTime.new(nil, :value => "20090505T093200Z" )]
      end
    end

    context "with conflicting timezones" do
      before(:each) do
        @event = RiCal.Event
      end

      it "should raise an InvalidPropertyValue if an argument does not match an explicit time zone" do
        lambda {RiCal::PropertyValue::OccurrenceList.convert(@event, "America/New_York", Time.now.set_tzid("America/Chicago"))}.should raise_error(RiCal::InvalidPropertyValue)
      end

      it "should raise an InvalidPropertyValue if the arguments have mixed time zones" do
        lambda {RiCal::PropertyValue::OccurrenceList.convert(@event, Time.now.set_tzid("America/New_York"), Time.now.set_tzid("America/Chicago"))}.should raise_error(RiCal::InvalidPropertyValue)
      end
    end

    context "with a tzid and a single datetime" do
      before(:each) do
        timezone = mock("Timezone",
          :rational_utc_offset => Rational(-5, 24),
          :local_to_utc => RiCal::PropertyValue.date_or_date_time(nil, :value => "19620220T194739"),
          :name => 'America/New_York'
          )

        timezone_finder = mock("tz_finder", :find_timezone => timezone, :default_tzid => "UTC", :tz_info_source? => true)
        @it = RiCal::PropertyValue::OccurrenceList.convert(timezone_finder, 'America/New_York', "19620220T144739")
      end

      it "should produce the right ical representation" do
        @it.to_s.should == ";TZID=America/New_York:19620220T144739"
      end

      context "its ruby value" do

        it "should be the right DateTime" do
          @it.ruby_value.should == [result_time_in_zone(1962, 2, 20, 14, 47, 39, 'America/New_York')]
        end

        it "should have the right tzid" do
          @it.ruby_value.first.tzid.should == "America/New_York"
        end
      end

      it "should have the right elements" do
        @it.send(:elements).should == [RiCal::PropertyValue::DateTime.new(nil, :params=> {'TZID' => 'America/New_York'}, :value => "19620220T144739" )]
      end
    end
  end
end