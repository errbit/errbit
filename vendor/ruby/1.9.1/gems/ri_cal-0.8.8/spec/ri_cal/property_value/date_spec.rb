#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe RiCal::PropertyValue::Date do
  context ".advance" do
    it "should advance by one week if passed :days => 7" do
      dt1 = RiCal::PropertyValue::Date.new(nil, :value => "20050131")
      dt2 = RiCal::PropertyValue::Date.new(nil, :value => "20050207")
      dt1.advance(:days => 7).should == dt2
    end

    context ".==" do
      it "should return true for two instances representing the same date" do
        dt1 = RiCal::PropertyValue::Date.new(nil, :value => DateTime.parse("20050131T010000"))
        dt2 = RiCal::PropertyValue::Date.new(nil, :value => DateTime.parse("20050131T010001"))
        dt1.should == dt2
      end
    end
  end

  context ".-" do

    it "should return a Duration property when the argument is also a Date property" do
      dt1 = RiCal::PropertyValue::Date.new(nil, :value => DateTime.parse("20090519"))
      dt2 = RiCal::PropertyValue::Date.new(nil, :value => DateTime.parse("20090518"))
      (dt1 - dt2).should == RiCal::PropertyValue::Duration.new(nil, :value => "+P1D")
    end

    it "should return a Duration property when the argument is a DateTime property" do
      dt1 = RiCal::PropertyValue::Date.new(nil, :value => DateTime.parse("20090519"))
      dt2 = RiCal::PropertyValue::DateTime.new(nil, :value => DateTime.parse("20090518T120000"))
      (dt1 - dt2).should == RiCal::PropertyValue::Duration.new(nil, :value => "+PT12H")
    end

    it "should return a DateTime property when the argument is a Duration Property" do
      dt1 = RiCal::PropertyValue::Date.new(nil, :value => "19980119")
      duration = RiCal::PropertyValue::Duration.new(nil, :value => "+PT2H")
      @it = dt1 - duration
      @it.should == RiCal::PropertyValue::DateTime.new(nil, :value => "19980118T220000")
    end
  end

  context ".+" do

    it "should return a DateTime property when the argument is a Duration Property" do
      dt1 = RiCal::PropertyValue::Date.new(nil, :value => "19980119")
      duration = RiCal::PropertyValue::Duration.new(nil, :value => "+PT2H")
      @it = dt1 + duration
      @it.should == RiCal::PropertyValue::DateTime.new(nil, :value => "19980119T020000")
    end
  end
end