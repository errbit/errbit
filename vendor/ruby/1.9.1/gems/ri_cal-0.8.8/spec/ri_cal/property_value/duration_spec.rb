#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])
require 'date'

describe RiCal::PropertyValue::Duration do

  context "with various values" do
    def value_expectations(dv, values = {})
      values = {:weeks => 0, :days => 0, :hours => 0, :minutes => 0, :seconds => 0}.merge(values)
      dv.weeks.should == values[:weeks]
      dv.days.should == values[:days]
      dv.hours.should == values[:hours]
      dv.minutes.should == values[:minutes]
      dv.seconds.should == values[:seconds]
    end

    it ".+P7W should have represent 7 weeks" do
      value_expectations(RiCal::PropertyValue::Duration.new(nil, :value => "+P7W"), :weeks => 7)
    end

    it ".P15DT5H0M20S should have represent 15 days, 5 hours and 20 seconds" do
      value_expectations(RiCal::PropertyValue::Duration.new(nil, :value => "P15DT5H0M20S"), :days => 15, :hours => 5, :seconds => 20)
    end

    it ".+P2D should have represent 2 days" do
      value_expectations(RiCal::PropertyValue::Duration.new(nil, :value => "+P2D"), :days => 2)
    end

    it ".+PT3H should have represent 3 hours" do
      value_expectations(RiCal::PropertyValue::Duration.new(nil, :value => "+PT3H"), :hours => 3)
    end

    it ".+PT15M should have represent 15 minutes" do
      value_expectations(RiCal::PropertyValue::Duration.new(nil, :value => "+PT15M"), :minutes => 15)
    end

    it ".+PT45S should have represent 45 seconds" do
      value_expectations(RiCal::PropertyValue::Duration.new(nil, :value => "+PT45S"), :seconds => 45)
    end
  end

  context ".==" do
    it "should return true for two durations of one day" do
      RiCal::PropertyValue.new(nil, :value => "+P1D").should == RiCal::PropertyValue.new(nil, :value => "+P1D")
    end
  end

  context ".from_datetimes" do

    context "starting at 11:00 pm, and ending at 1:01:02 am the next day" do
      before(:each) do
        @it = RiCal::PropertyValue::Duration.from_datetimes(nil,
        DateTime.parse("Sep 1, 2008 23:00"),
        DateTime.parse("Sep 2, 2008 1:01:02")
        )
      end

      it "should produce a duration" do
        @it.class.should == RiCal::PropertyValue::Duration
      end

      it "should have a value of '+P2H1M2S'" do
        @it.value.should == '+PT2H1M2S'
      end

      it "should contain zero days" do
        @it.days.should == 0
      end

      it "should contain two hours" do
        @it.hours.should == 2
      end

      it "should contain one minute" do
        @it.minutes.should == 1
      end

      it "should contain one minute" do
        @it.minutes.should == 1
      end
    end

    context "starting at 00:00, and ending at 00:00 the next day" do
      before(:each) do
        @it = RiCal::PropertyValue::Duration.from_datetimes(nil,
        DateTime.parse("Sep 1, 2008 00:00"),
        DateTime.parse("Sep 2, 2008 00:00")
        )
      end

      it "should produce a duration" do
        @it.class.should == RiCal::PropertyValue::Duration
      end

      it "should have a value of '+P1D'" do
        @it.value.should == '+P1D'
      end

      it "should contain zero days" do
        @it.days.should == 1
      end

      it "should contain zero hours" do
        @it.hours.should == 0
      end

      it "should contain zero minutes" do
        @it.minutes.should == 0
      end

      it "should contain zero minutes" do
        @it.minutes.should == 0
      end
    end

    it "should work when start > finish" do
      lambda {
        RiCal::PropertyValue::Duration.from_datetimes(nil,
        DateTime.parse("Sep 2, 2008 1:01:02"),
        DateTime.parse("Sep 1, 2008 23:00")
        )
        }.should_not raise_error(ArgumentError)
      end
    end
  end