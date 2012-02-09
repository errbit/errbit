#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe RiCal::PropertyValue::RecurrenceRule::RecurringYearDay do

  def set_it(which, rule=nil)
    @it = RiCal::PropertyValue::RecurrenceRule::RecurringYearDay.new(which, rule)
  end
  
  def time_property(str)
    RiCal::PropertyValue.date_or_date_time(nil, :value => str)
  end

  describe ".matches_for(time)" do

    it "should return an array containing January 1, in the times year for the the 1st day" do
      set_it(1).matches_for(time_property("19970603T090000")).should == [time_property("19970101T090000")]
    end
  end
end