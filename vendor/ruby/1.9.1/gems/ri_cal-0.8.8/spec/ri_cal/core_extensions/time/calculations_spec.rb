#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe RiCal::CoreExtensions::Time::Calculations do

  describe ".iso_week_num" do

    it "should calculate week 1 for January 1, 2001 for a wkst of 1 (Monday)" do
      Date.new(2001, 1,1).iso_week_num(1).should == 1
    end

    it "should calculate week 1 for January 7, 2001 for a wkst of 1 (Monday)" do
      Date.new(2001, 1,7).iso_week_num(1).should == 1
    end

    it "should calculate week 2 for January 8, 2001 for a wkst of 1 (Monday)" do
      Date.new(2001, 1,8).iso_week_num(1).should == 2
    end

    it "should calculate week 52 for December 31, 2000 for a wkst of 1 (Monday)" do
      Date.new(2000, 12,31).iso_week_num(1).should == 52
    end

    it "should calculate week 52 for January 1, 2001 for a wkst of 2 (Tuesday)" do
      Date.new(2001, 1, 1).iso_week_num(2).should == 52
    end

    it "should calculate week 1 for Dec 31, 2003 for a wkst of 1 (Monday)" do
      Date.new(2003, 12, 31).iso_week_num(1).should == 1
    end
  end
  
  describe ".iso_year" do
    it "should be 1999 for January 2 2000" do
      Date.new(2000, 1, 2).iso_year(1).should == 1999
    end
    
    it "should be 1998 for December 29, 1997" do
      Date.new(1997, 12, 29).iso_year(1).should == 1998
    end
  end

  describe ".iso_year_start" do

    it "should calculate January 4 1999 for January 2 2000 for a wkst of 1 (Monday)" do
      Date.new(2000, 1, 2).iso_year_start(1).to_s.should == Date.new(1999, 1, 4).to_s
    end

    it "should calculate January 3 2000 for January 3 2000 for a wkst of 1 (Monday)" do
      Date.new(2000, 1, 3).iso_year_start(1).to_s.should == Date.new(2000, 1, 3).to_s
    end

    it "should calculate January 3 2000 for January 4 2000 for a wkst of 1 (Monday)" do
      Date.new(2000, 1, 4).iso_year_start(1).to_s.should == Date.new(2000, 1, 3).to_s
    end

    it "should calculate January 3 2000 for December 31 2000 for a wkst of 1 (Monday)" do
      Date.new(2000, 12, 31).iso_year_start(1).to_s.should == Date.new(2000, 1, 3).to_s
    end

    it "should calculate week January 1, 2001 for January 1, 2001 for a wkst of 1 (Monday)" do
      Date.new(2001, 1,1).iso_year_start(1).should == Date.new(2001, 1, 1)
    end

    it "should calculate week January 1, 2001 for July 4, 2001 for a wkst of 1 (Monday)" do
      Date.new(2001, 7,4).iso_year_start(1).should == Date.new(2001, 1, 1)
    end

    it "should calculate January 3 2000 for January 3 2000" do
      Date.new(2000, 1, 3).iso_year_start(1).to_s.should == Date.new(2000, 1, 3).to_s
    end

    it "should calculate January 3 2000 for January 4 2000" do
      Date.new(2000, 1, 4).iso_year_start(1).to_s.should == Date.new(2000, 1, 3).to_s
    end

    # it "should calculate week 1 for January 7, 2001 for a wkst of 1 (Monday)" do
    #   Date.new(2001, 1,7).iso_week_num(1).should == 1
    # end
    #
    # it "should calculate week 2 for January 8, 2001 for a wkst of 1 (Monday)" do
    #   Date.new(2001, 1,8).iso_week_num(1).should == 2
    # end
    #
    # it "should calculate week 52 for December 31, 2000 for a wkst of 1 (Monday)" do
    #   Date.new(2000, 12,31).iso_week_num(1).should == 52
    # end
    #
    # it "should calculate week 52 for January 1, 2001 for a wkst of 2 (Tuesday)" do
    #   Date.new(2001, 1, 1).iso_week_num(2).should == 52
    # end
    #
    # it "should calculate week 1 for Dec 31, 2003 for a wkst of 1 (Monday)" do
    #   Date.new(2003, 12, 31).iso_week_num(1).should == 1
    # end
  end

  describe "#iso_week_one" do

    before(:each) do
      @it = RiCal::CoreExtensions::Time::Calculations
    end

    describe "with a monday week start" do
      it "should return Jan 3, 2000 for 2000" do
        @it.iso_week_one(2000, 1).should == Date.new(2000, 1, 3)
      end

      it "should return Jan 1, 2001 for 2001" do
        @it.iso_week_one(2001, 1).should == Date.new(2001, 1,1)
      end

      it "should return Dec 31, 2001 for 2002" do
        @it.iso_week_one(2002, 1).should == Date.new(2001, 12, 31)
      end

      it "should return Dec 30, 2002 for 2003" do
        @it.iso_week_one(2003, 1).should == Date.new(2002, 12, 30)
      end

      it "should return Dec 29, 2003 for 2004" do
        @it.iso_week_one(2004, 1).should == Date.new(2003, 12, 29)
      end
    end

    it "should return Jan 2, 2001 for 2001 with a Tuesday week start" do
      @it.iso_week_one(2001, 2).should == Date.new(2001, 1, 2)
    end

    it "should return Jan 3, 2001 for 2001 with a Wednesday week start" do
      @it.iso_week_one(2001, 3).should == Date.new(2001, 1, 3)
    end

    it "should return Jan 4, 2001 for 2001 with a Thursday week start" do
      @it.iso_week_one(2001, 4).should == Date.new(2001, 1, 4)
    end

    it "should return Dec 29, 2000 for 2001 with a Friday week start" do
      @it.iso_week_one(2001, 5).should == Date.new(2000, 12, 29)
    end

    it "should return Dec 30, 2000 for 2001 with a Saturday week start" do
      @it.iso_week_one(2001, 6).should == Date.new(2000, 12, 30)
    end

    it "should return Dec 31, 2000 for 2001 with a Sunday week start" do
      @it.iso_week_one(2001, 0).should == Date.new(2000, 12, 31)
    end
  end

  describe ".leap_year?" do
    it "should return true for 2000" do
      Date.parse("1/3/2000").should be_leap_year
    end

    it "should return false for 2007" do
      Date.parse("1/3/2007").should_not be_leap_year
    end

    it "should return true for 2008" do
      Date.parse("1/3/2008").should be_leap_year
    end

    it "should return false for 2100" do
      Date.parse("1/3/2100").should_not be_leap_year
    end
  end

  describe ".days_in_month" do

    it "should return 29 for February in a leap year" do
      Date.new(2008, 2, 1).days_in_month.should == 29
    end

    it "should return 28 for February in a non-leap year" do
      Date.new(2009, 2, 1).days_in_month.should == 28
    end

    it "should return 31 for January in a leap year" do
      Date.new(2008, 1, 1).days_in_month.should == 31
    end

    it "should return 31 for January in a non-leap year" do
      Date.new(2009, 1, 1).days_in_month.should == 31
    end
  end
end