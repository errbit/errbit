#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe RiCal::CoreExtensions::Time::WeekDayPredicates do

  describe ".nth_wday_in_month" do
    it "should return Feb 28, 2005 for the 4th Monday for a date in February 2005" do
      expected = RiCal::PropertyValue::Date.new(nil, :value => "20050228")
      it = Date.parse("Feb 7, 2005").nth_wday_in_month(4, 1)
      it.should == expected
    end
  end

  describe ".nth_wday_in_month?" do
    it "should return true for Feb 28, 2005 for the 4th Monday" do
      Date.parse("Feb 28, 2005").nth_wday_in_month?(4, 1).should be
    end
  end

  describe ".start_of_week_with_wkst" do
    describe "for Wednesday Sept 10 1997" do
      before(:each) do
        @date = Date.parse("Sept 10, 1997")
      end

      it "should return a Date of Sept 7, 1997 00:00 for a wkst of 0 - Sunday" do
        @date.start_of_week_with_wkst(0).should == Date.parse("Sept 7, 1997")
      end

      it "should return a Date of Sept 8, 1997 00:00 for a wkst of 1 - Monday" do
        @date.start_of_week_with_wkst(1).should == Date.parse("Sept 8, 1997")
      end

      it "should return a Date of Sept 10, 1997 00:00 for a wkst of 3 - Wednesday" do
        @date.start_of_week_with_wkst(3).should == Date.parse("Sept 10, 1997")
      end

      it "should return a Date of Sept 4, 1997 00:00 for a wkst of 4 - Thursday" do
        @date.start_of_week_with_wkst(4).should == Date.parse("Sept 4, 1997")
      end
    end

  end
end
