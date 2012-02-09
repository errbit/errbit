#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. spec_helper])

require 'tzinfo'

describe RiCal::RequiredTimezones::RequiredTimezone do

  before(:each) do
    @tzid = "America/New_York"
    @it = RiCal::RequiredTimezones::RequiredTimezone.new(@tzid)
  end

  it "should have the right timezone" do
    @it.timezone.identifier.should == @tzid
  end

  it "should set the first_time to the first date_time added" do
    dt1 = dt_prop(DateTime.parse("Mar 22, 2009 10:48"))
    @it.add_datetime(dt1)
    @it.first_time.should == dt1
  end

  it "should set the first_time to the earliest time added" do
    dt1 = dt_prop(DateTime.parse("Mar 22, 2009 10:48"))
    dt2 = dt_prop(DateTime.parse("Mar 22, 2009 9:00"))
    dt3 = dt_prop(DateTime.parse("Mar 22, 2009 10:00"))
    @it.add_datetime(dt1)
    @it.add_datetime(dt2)
    @it.add_datetime(dt3)
    @it.first_time.should == dt2
  end

  it "should set the last_time to the first date_time added" do
    dt1 = dt_prop(DateTime.parse("Mar 22, 2009 10:48"))
    @it.add_datetime(dt1)
    @it.last_time.should == dt1
  end

  it "should set the first_time to the earliest time added" do
    dt1 = dt_prop(DateTime.parse("Mar 22, 2009 10:48"))
    dt2 = dt_prop(DateTime.parse("Mar 22, 2009 9:00"))
    dt3 = dt_prop(DateTime.parse("Mar 22, 2009 10:00"))
    @it.add_datetime(dt1)
    @it.add_datetime(dt2)
    @it.add_datetime(dt3)
    @it.last_time.should == dt1
  end
end

describe RiCal::RequiredTimezones do
  before(:each) do
    @it = RiCal::RequiredTimezones.new
  end
  
  def localtime_and_zone(date_time, tzid = "US/Eastern")
    [dt_prop(DateTime.parse(date_time), tzid), tzid]
  end
  

  it "should create a RequiredTimezone for each new timezone presented" do
    @it.add_datetime(*localtime_and_zone("Mar 22, 2009 1:00"))
    @it.add_datetime(*localtime_and_zone("Apr 16, 2008 12:00", "US/Central"))
    @it.add_datetime(*localtime_and_zone("Apr 16, 2008 12:00"))
    @it.required_zones.map {|zone| zone.tzid}.sort.should == ["US/Central", "US/Eastern"]
  end
end