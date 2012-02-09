#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

require 'rubygems'

FirstOfMonth = RiCal::PropertyValue::RecurrenceRule::RecurringMonthDay.new(1)
TenthOfMonth = RiCal::PropertyValue::RecurrenceRule::RecurringMonthDay.new(10)
FirstOfYear = RiCal::PropertyValue::RecurrenceRule::RecurringYearDay.new(1)
TenthOfYear = RiCal::PropertyValue::RecurrenceRule::RecurringYearDay.new(10)
SecondWeekOfYear = RiCal::PropertyValue::RecurrenceRule::RecurringNumberedWeek.new(2)
LastWeekOfYear = RiCal::PropertyValue::RecurrenceRule::RecurringNumberedWeek.new(-1)

# rfc 2445 4.3.10 p.40
describe RiCal::PropertyValue::RecurrenceRule do

  describe "initialized from hash" do
    it "should require a frequency" do
      @it = RiCal::PropertyValue::RecurrenceRule.new(nil, {})
      @it.should_not be_valid
      @it.errors.should include("RecurrenceRule must have a value for FREQ")
    end
  
    it "accept reject an invalid frequency" do
      @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "blort")
      @it.should_not be_valid
      @it.errors.should include("Invalid frequency 'blort'")
    end
  
    %w{secondly SECONDLY minutely MINUTELY hourly HOURLY daily DAILY weekly WEEKLY monthly MONTHLY
      yearly YEARLY
      }.each do | freq_val |
        it "should accept a frequency of #{freq_val}" do
          RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => freq_val).should be_valid
        end
      end
  
    it "should reject setting both until and count" do
      @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :until => Time.now, :count => 10)
      @it.should_not be_valid
      @it.errors.should include("COUNT and UNTIL cannot both be specified")
    end
  
    describe "interval parameter" do
  
      # p 42
      it "should default to 1" do
        RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily").interval.should == 1
      end
  
      it "should accept an explicit value" do
        RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :interval => 42).interval.should == 42
      end
  
      it "should reject a negative value" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :interval => -1)
        @it.should_not be_valid
      end
    end
  
    describe "bysecond parameter" do
  
      it "should accept a single integer" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bysecond => 10)
        @it.send(:by_list)[:bysecond].should == [10]
      end
  
      it "should accept an array of integers" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bysecond => [10, 20])
        @it.send(:by_list)[:bysecond].should == [10, 20]
      end
  
      it "should reject invalid values" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bysecond => [-1, 0, 59, 60])
        @it.should_not be_valid
        @it.errors.should == ['-1 is invalid for bysecond', '60 is invalid for bysecond']
      end
    end
  
    describe "byminute parameter" do
   
       it "should accept a single integer" do
         @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byminute => 10)
         @it.send(:by_list)[:byminute].should == [10]
       end
   
       it "should accept an array of integers" do
         @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byminute => [10, 20])
         @it.send(:by_list)[:byminute].should == [10, 20]
       end
   
       it "should reject invalid values" do
         @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byminute => [-1, 0, 59, 60])
         @it.should_not be_valid
         @it.errors.should == ['-1 is invalid for byminute', '60 is invalid for byminute']
       end
     end
   
     describe "byhour parameter" do
   
       it "should accept a single integer" do
         @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byhour => 10)
         @it.send(:by_list)[:byhour].should == [10]
       end
   
       it "should accept an array of integers" do
         @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byhour => [10, 12])
         @it.send(:by_list)[:byhour].should == [10, 12]
       end
   
      it "should reject invalid values" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byhour => [-1, 0, 23, 24])
        @it.should_not be_valid
        @it.errors.should == ['-1 is invalid for byhour', '24 is invalid for byhour']
      end
    end
  
    describe "byday parameter" do
      
      def anyMonday(rule)
        RiCal::PropertyValue::RecurrenceRule::RecurringDay.new("MO", rule)
      end
      
      def anyWednesday(rule)
        RiCal::PropertyValue::RecurrenceRule::RecurringDay.new("WE", rule)
      end
      
  
      it "should accept a single value" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byday => 'MO')
        @it.send(:by_list)[:byday].should == [anyMonday(@it)]
      end
  
      it "should accept an array of values" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byday => ['MO', 'WE'])
        @it.send(:by_list)[:byday].should == [anyMonday(@it), anyWednesday(@it)]
      end
  
      it "should reject invalid values" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byday => ['VE'])
        @it.should_not be_valid
        @it.errors.should == ['"VE" is not a valid day']
      end
    end
  
    describe "bymonthday parameter" do
  
      it "should accept a single value" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bymonthday => 1)
        @it.send(:by_list)[:bymonthday].should == [FirstOfMonth]
      end
  
      it "should accept an array of values" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bymonthday => [1, 10])
        @it.send(:by_list)[:bymonthday].should == [FirstOfMonth, TenthOfMonth]
      end
  
      it "should reject invalid values" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bymonthday => [0, 32, 'VE'])
        @it.should_not be_valid
        @it.errors.should == ['0 is not a valid month day','32 is not a valid month day', '"VE" is not a valid month day']
      end
    end
  
    describe "byyearday parameter" do
  
      it "should accept a single value" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byyearday => 1)
        @it.send(:by_list)[:byyearday].should == [FirstOfYear]
      end
  
       it "should accept an array of values" do
         @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byyearday => [1, 10])
         @it.send(:by_list)[:byyearday].should == [FirstOfYear, TenthOfYear]
       end
   
       it "should reject invalid values" do
         @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byyearday => [0, 370, 'VE'])
         @it.should_not be_valid
         @it.errors.should == ['0 is not a valid year day', '370 is not a valid year day', '"VE" is not a valid year day']
       end
     end
   
     describe "byweekno parameter" do
   
       it "should accept a single value" do
         @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byweekno => 2)
         @it.send(:by_list)[:byweekno].should == [SecondWeekOfYear]
       end
   
       it "should accept an array of values" do
         @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byweekno => [2, -1])
         @it.send(:by_list)[:byweekno].should == [SecondWeekOfYear, LastWeekOfYear]
       end
   
       it "should reject invalid values" do
         @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byweekno => [0, 54, 'VE'])
         @it.should_not be_valid
         @it.errors.should == ['0 is not a valid week number', '54 is not a valid week number', '"VE" is not a valid week number']
       end
     end
   
     describe "bymonth parameter" do
  
      it "should accept a single integer" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bymonth => 10)
        @it.send(:by_list)[:bymonth].should == [10]
      end
  
      it "should accept an array of integers" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bymonth => [10, 12])
        @it.send(:by_list)[:bymonth].should == [10, 12]
      end
  
      it "should reject invalid values" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bymonth => [-1, 0, 1, 12, 13])
        @it.should_not be_valid
        @it.errors.should == ['-1 is invalid for bymonth', '0 is invalid for bymonth', '13 is invalid for bymonth']
      end
    end
  
    describe "bysetpos parameter" do
  
      it "should accept a single integer" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bymonth => 10, :bysetpos => 2)
        @it.send(:by_list)[:bysetpos].should == [2]
      end
  
      it "should accept an array of integers" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bymonth => 10, :bysetpos => [2, 3])
        @it.send(:by_list)[:bysetpos].should == [2, 3]
      end
  
      it "should reject invalid values" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bymonth => 10, :bysetpos => [-367, -366, -1, 0, 1, 366, 367])
        @it.should_not be_valid
        @it.errors.should == ['-367 is invalid for bysetpos', '0 is invalid for bysetpos', '367 is invalid for bysetpos']
      end
  
      it "should require another BYxxx rule part" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bysetpos => 2)
        @it.should_not be_valid
        @it.errors.should == ['bysetpos cannot be used without another by_xxx rule part']
      end
    end
  
    describe "wkst parameter" do
  
      it "should default to MO" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily")
        @it.wkst.should == 'MO'
      end
  
      it "should accept a single string" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :wkst => 'SU')
        @it.wkst.should == 'SU'
      end
  
      %w{MO TU WE TH FR SA SU}.each do |valid|
        it "should accept #{valid} as a valid value" do
          RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :wkst => valid).should be_valid
        end
      end
  
      it "should reject invalid values" do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :wkst => "bogus")
        @it.should_not be_valid
        @it.errors.should == ['"bogus" is invalid for wkst']
      end
    end
  
    describe "freq accessors" do
      before(:each) do
        @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => 'daily')
      end
  
      it "should convert the initial value to uppercase" do
        @it.freq.should == 'DAILY'
      end
  
      it "should convert the setter value to uppercase " do
        @it.freq = 'weekly'
        @it.freq.should == 'WEEKLY'
      end
  
      it "should not accept an invalid value" do
        @it.freq = 'bogus'
        @it.should_not be_valid
      end
    end
  end
  
  describe "initialized from parser" do
  
    describe "from 'FREQ=YEARLY;INTERVAL=2;BYMONTH=1;BYDAY=SU;BYHOUR=8,9;BYMINUTE=30'" do
  
      before(:all) do
        lambda {
          @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :value => 'FREQ=YEARLY;INTERVAL=2;BYMONTH=1;BYDAY=SU;BYHOUR=8,9;BYMINUTE=30')
          }.should_not raise_error
      end
      
      it "should have a frequency of yearly" do
        @it.freq.should == "YEARLY"
      end
      
      it "should have an interval of 2" do
        @it.interval.should == 2
      end
    end
  end
  
  describe "to_ical" do
  
    it "should handle basic cases" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily").to_ical.should == "FREQ=DAILY"
    end
  
    it "should handle multiple parts" do
      @it = RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :count => 10, :interval => 2).to_ical
      @it.should match(/^FREQ=DAILY;/)
      parts = @it.split(';')
      parts.should include("COUNT=10")
      parts.should include("INTERVAL=2")
    end
  
    it "should supress the default interval value" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :interval => 1).to_ical.should_not match(/INTERVAL=/)
    end
  
    it "should support the wkst value" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :wkst => 'SU').to_ical.split(";").should include("WKST=SU")
    end
  
    it "should supress the default wkst value" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :wkst => 'MO').to_ical.split(";").should_not include("WKST=SU")
    end
  
    it "should handle a scalar bysecond" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bysecond => 15).to_ical.split(";").should include("BYSECOND=15")
    end
  
    it "should handle an array bysecond" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bysecond => [15, 45]).to_ical.split(";").should include("BYSECOND=15,45")
    end
  
    it "should handle a scalar byday" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "monthly", :byday => 'MO').to_ical.split(";").should include("BYDAY=MO")
    end
  
    it "should handle an array byday" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byday => ["MO", "-3SU"]).to_ical.split(";").should include("BYDAY=MO,-3SU")
    end
  
    it "should handle a scalar bymonthday" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "monthly", :bymonthday => 14).to_ical.split(";").should include("BYMONTHDAY=14")
    end
  
    it "should handle an array bymonthday" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bymonthday => [15, -10]).to_ical.split(";").should include("BYMONTHDAY=15,-10")
    end
  
    it "should handle a scalar byyearday" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "monthly", :byyearday => 14).to_ical.split(";").should include("BYYEARDAY=14")
    end
  
    it "should handle an array byyearday" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byyearday => [15, -10]).to_ical.split(";").should include("BYYEARDAY=15,-10")
    end
  
    it "should handle a scalar byweekno" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "monthly", :byweekno => 14).to_ical.split(";").should include("BYWEEKNO=14")
    end
  
    it "should handle an array byyearday" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :byweekno => [15, -10]).to_ical.split(";").should include("BYWEEKNO=15,-10")
    end
  
    it "should handle a scalar bymonth" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "monthly", :bymonth => 2).to_ical.split(";").should include("BYMONTH=2")
    end
  
    it "should handle an array bymonth" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :bymonth => [5, 6]).to_ical.split(";").should include("BYMONTH=5,6")
    end
  
    it "should handle a scalar bysetpos" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "monthly", :byday => %w{MO TU WE TH FR}, :bysetpos => -1).to_ical.split(";").should include("BYSETPOS=-1")
    end
  
    it "should handle an array bysetpos" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "monthly", :byday => %w{MO TU WE TH FR}, :bysetpos => [2, -1]).to_ical.split(";").should include("BYSETPOS=-1,2")
    end

    it "should handle until as a date" do
      RiCal::PropertyValue::RecurrenceRule.new(nil, :freq => "daily", :until => Date.new(2009,10,17)).to_ical.should include("UNTIL=20091017")
    end
  end
  
  def ruby19_date_str_fix(string)
  end
  
  describe "#enumerator" do

    def self.enumeration_spec(description, dtstart_string, tzid, rrule_string, expectation, debug=false)
      if expectation.last == "..."
        expectation = expectation[0..-2]
        iterations = expectation.length
      else
        iterations = expectation.length + 1
      end

      describe description do
        before(:each) do
          RiCal.debug = debug
          rrule = RiCal::PropertyValue::RecurrenceRule.new(nil, :value => rrule_string)
          default_start_time = RiCal::PropertyValue::DateTime.new(nil, :value => dtstart_string, :tzid => tzid)
          @enum = rrule.enumerator(mock("EventValue", :default_start_time => default_start_time, :default_duration => nil))
          @expectations = (expectation.map {|str| RiCal::PropertyValue::DateTime.new(nil, :value => str.gsub(/E.T$/,''), :tzid => tzid)})
        end
        
        after(:each) do
          RiCal.debug = false
        end
        
        after(:each) do
          RiCal.debug = false
        end

        it "should produce the correct occurrences" do
          actuals = []
          (0..(iterations-1)).each do |i|
            occurrence = @enum.next_occurrence
            break if occurrence.nil?
            actuals << occurrence.dtstart
            # This is a little strange, we do this to avoid O(n*2)
            unless actuals.last == @expectations[i]
              actuals.should == @expectations[0,actuals.length]
            end
          end
          actuals.length.should == @expectations.length
        end
      end
    end

      enumeration_spec(
      "Daily for 10 occurrences (RFC 2445 p 118)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=DAILY;COUNT=10",
      [
        "Sep 2, 1997 9:00 AM EDT",
        "Sep 3, 1997 9:00 AM EDT",
        "Sep 4, 1997 9:00 AM EDT",
        "Sep 5, 1997 9:00 AM EDT",
        "Sep 6, 1997 9:00 AM EDT",
        "Sep 7, 1997 9:00 AM EDT",
        "Sep 8, 1997 9:00 AM EDT",
        "Sep 9, 1997 9:00 AM EDT",
        "Sep 10, 1997 9:00 AM EDT",
        "Sep 11, 1997 9:00 AM EDT"
      ]
      )

      enumeration_spec(
      "Daily until December 24, 1997 (RFC 2445 p 118)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=DAILY;UNTIL=19971224T000000Z",
      [
        "Sep 2, 1997 9:00 AM EDT",
        "Sep 3, 1997 9:00 AM EDT",
        "Sep 4, 1997 9:00 AM EDT",
        "Sep 5, 1997 9:00 AM EDT",
        "Sep 6, 1997 9:00 AM EDT",
        "Sep 7, 1997 9:00 AM EDT",
        "Sep 8, 1997 9:00 AM EDT",
        "Sep 9, 1997 9:00 AM EDT",
        "Sep 10, 1997 9:00 AM EDT",
        "Sep 11, 1997 9:00 AM EDT",
        "Sep 12, 1997 9:00 AM EDT",
        "Sep 13, 1997 9:00 AM EDT",
        "Sep 14, 1997 9:00 AM EDT",
        "Sep 15, 1997 9:00 AM EDT",
        "Sep 16, 1997 9:00 AM EDT",
        "Sep 17, 1997 9:00 AM EDT",
        "Sep 18, 1997 9:00 AM EDT",
        "Sep 19, 1997 9:00 AM EDT",
        "Sep 20, 1997 9:00 AM EDT",
        "Sep 21, 1997 9:00 AM EDT",
        "Sep 22, 1997 9:00 AM EDT",
        "Sep 23, 1997 9:00 AM EDT",
        "Sep 24, 1997 9:00 AM EDT",
        "Sep 25, 1997 9:00 AM EDT",
        "Sep 26, 1997 9:00 AM EDT",
        "Sep 27, 1997 9:00 AM EDT",
        "Sep 28, 1997 9:00 AM EDT",
        "Sep 29, 1997 9:00 AM EDT",
        "Sep 30, 1997 9:00 AM EDT",
        "Oct 1, 1997 9:00 AM EDT",
        "Oct 2, 1997 9:00 AM EDT",
        "Oct 3, 1997 9:00 AM EDT",
        "Oct 4, 1997 9:00 AM EDT",
        "Oct 5, 1997 9:00 AM EDT",
        "Oct 6, 1997 9:00 AM EDT",
        "Oct 7, 1997 9:00 AM EDT",
        "Oct 8, 1997 9:00 AM EDT",
        "Oct 9, 1997 9:00 AM EDT",
        "Oct 10, 1997 9:00 AM EDT",
        "Oct 11, 1997 9:00 AM EDT",
        "Oct 12, 1997 9:00 AM EDT",
        "Oct 13, 1997 9:00 AM EDT",
        "Oct 14, 1997 9:00 AM EDT",
        "Oct 15, 1997 9:00 AM EDT",
        "Oct 16, 1997 9:00 AM EDT",
        "Oct 17, 1997 9:00 AM EDT",
        "Oct 18, 1997 9:00 AM EDT",
        "Oct 19, 1997 9:00 AM EDT",
        "Oct 20, 1997 9:00 AM EDT",
        "Oct 21, 1997 9:00 AM EDT",
        "Oct 22, 1997 9:00 AM EDT",
        "Oct 23, 1997 9:00 AM EDT",
        "Oct 24, 1997 9:00 AM EDT",
        "Oct 25, 1997 9:00 AM EDT",
        "Oct 26, 1997 9:00 AM EST",
        "Oct 27, 1997 9:00 AM EST",
        "Oct 28, 1997 9:00 AM EST",
        "Oct 29, 1997 9:00 AM EST",
        "Oct 30, 1997 9:00 AM EST",
        "Oct 31, 1997 9:00 AM EST",
        "Nov 01, 1997 9:00 AM EST",
        "Nov 02, 1997 9:00 AM EST",
        "Nov 03, 1997 9:00 AM EST",
        "Nov 04, 1997 9:00 AM EST",
        "Nov 05, 1997 9:00 AM EST",
        "Nov 06, 1997 9:00 AM EST",
        "Nov 07, 1997 9:00 AM EST",
        "Nov 08, 1997 9:00 AM EST",
        "Nov 09, 1997 9:00 AM EST",
        "Nov 10, 1997 9:00 AM EST",
        "Nov 11, 1997 9:00 AM EST",
        "Nov 12, 1997 9:00 AM EST",
        "Nov 13, 1997 9:00 AM EST",
        "Nov 14, 1997 9:00 AM EST",
        "Nov 15, 1997 9:00 AM EST",
        "Nov 16, 1997 9:00 AM EST",
        "Nov 17, 1997 9:00 AM EST",
        "Nov 18, 1997 9:00 AM EST",
        "Nov 19, 1997 9:00 AM EST",
        "Nov 20, 1997 9:00 AM EST",
        "Nov 21, 1997 9:00 AM EST",
        "Nov 22, 1997 9:00 AM EST",
        "Nov 23, 1997 9:00 AM EST",
        "Nov 24, 1997 9:00 AM EST",
        "Nov 25, 1997 9:00 AM EST",
        "Nov 26, 1997 9:00 AM EST",
        "Nov 27, 1997 9:00 AM EST",
        "Nov 28, 1997 9:00 AM EST",
        "Nov 29, 1997 9:00 AM EST",
        "Nov 30, 1997 9:00 AM EST",
        "Dec 01, 1997 9:00 AM EST",
        "Dec 02, 1997 9:00 AM EST",
        "Dec 03, 1997 9:00 AM EST",
        "Dec 04, 1997 9:00 AM EST",
        "Dec 05, 1997 9:00 AM EST",
        "Dec 06, 1997 9:00 AM EST",
        "Dec 07, 1997 9:00 AM EST",
        "Dec 08, 1997 9:00 AM EST",
        "Dec 09, 1997 9:00 AM EST",
        "Dec 10, 1997 9:00 AM EST",
        "Dec 11, 1997 9:00 AM EST",
        "Dec 12, 1997 9:00 AM EST",
        "Dec 13, 1997 9:00 AM EST",
        "Dec 14, 1997 9:00 AM EST",
        "Dec 15, 1997 9:00 AM EST",
        "Dec 16, 1997 9:00 AM EST",
        "Dec 17, 1997 9:00 AM EST",
        "Dec 18, 1997 9:00 AM EST",
        "Dec 19, 1997 9:00 AM EST",
        "Dec 20, 1997 9:00 AM EST",
        "Dec 21, 1997 9:00 AM EST",
        "Dec 22, 1997 9:00 AM EST",
        "Dec 23, 1997 9:00 AM EST",
      ]
      )
      
      enumeration_spec(
      "Every other day - forever (RFC 2445 p 118)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=DAILY;INTERVAL=2",
      [
        "Sep 2, 1997 9:00 AM EDT",
        "Sep 4, 1997 9:00 AM EDT",
        "Sep 6, 1997 9:00 AM EDT",
        "Sep 8, 1997 9:00 AM EDT",
        "Sep 10, 1997 9:00 AM EDT",
        "Sep 12, 1997 9:00 AM EDT",
        "Sep 14, 1997 9:00 AM EDT",
        "Sep 16, 1997 9:00 AM EDT",
        "Sep 18, 1997 9:00 AM EDT",
        "Sep 20, 1997 9:00 AM EDT",
        "Sep 22, 1997 9:00 AM EDT",
        "Sep 24, 1997 9:00 AM EDT",
        "Sep 26, 1997 9:00 AM EDT",
        "Sep 28, 1997 9:00 AM EDT",
        "Sep 30, 1997 9:00 AM EDT",
        "Oct 2, 1997 9:00 AM EDT",
        "Oct 4, 1997 9:00 AM EDT",
        "Oct 6, 1997 9:00 AM EDT",
        "Oct 8, 1997 9:00 AM EDT",
        "Oct 10, 1997 9:00 AM EDT",
        "Oct 12, 1997 9:00 AM EDT",
        "Oct 14, 1997 9:00 AM EDT",
        "Oct 16, 1997 9:00 AM EDT",
        "Oct 18, 1997 9:00 AM EDT",
        "Oct 20, 1997 9:00 AM EDT",
        "Oct 22, 1997 9:00 AM EDT",
        "Oct 24, 1997 9:00 AM EDT",
        "Oct 26, 1997 9:00 AM EST",
        "Oct 28, 1997 9:00 AM EST",
        "Oct 30, 1997 9:00 AM EST",
        "Nov 01, 1997 9:00 AM EST",
        "Nov 03, 1997 9:00 AM EST",
        "Nov 05, 1997 9:00 AM EST",
        "Nov 07, 1997 9:00 AM EST",
        "Nov 09, 1997 9:00 AM EST",
        "Nov 11, 1997 9:00 AM EST",
        "Nov 13, 1997 9:00 AM EST",
        "Nov 15, 1997 9:00 AM EST",
        "Nov 17, 1997 9:00 AM EST",
        "Nov 19, 1997 9:00 AM EST",
        "Nov 21, 1997 9:00 AM EST",
        "Nov 23, 1997 9:00 AM EST",
        "Nov 25, 1997 9:00 AM EST",
        "Nov 27, 1997 9:00 AM EST",
        "Nov 29, 1997 9:00 AM EST",
        "Dec 01, 1997 9:00 AM EST",
        "Dec 03, 1997 9:00 AM EST",
        "..."
      ]
      )
      
      enumeration_spec(
      "Every 10 days, 5 occurrences (RFC 2445 p 118-19)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=DAILY;INTERVAL=10;COUNT=5",
      [
        "Sep 2, 1997 9:00 AM EDT",
        "Sep 12, 1997 9:00 AM EDT",
        "Sep 22, 1997 9:00 AM EDT",
        "Oct 2, 1997 9:00 AM EDT",
        "Oct 12, 1997 9:00 AM EDT"
      ]
      )
      
      enumeration_spec(
      "Everyday in January, for 3 years (RFC 2445 p 119)",
      "19980101T090000",
      "US-Eastern",
      "FREQ=DAILY;UNTIL=20000131T090000Z;BYMONTH=1",
      [
        "Jan 01, 1998 9:00 AM EST",
        "Jan 02, 1998 9:00 AM EST",
        "Jan 03, 1998 9:00 AM EST",
        "Jan 04, 1998 9:00 AM EST",
        "Jan 05, 1998 9:00 AM EST",
        "Jan 06, 1998 9:00 AM EST",
        "Jan 07, 1998 9:00 AM EST",
        "Jan 08, 1998 9:00 AM EST",
        "Jan 09, 1998 9:00 AM EST",
        "Jan 10, 1998 9:00 AM EST",
        "Jan 11, 1998 9:00 AM EST",
        "Jan 12, 1998 9:00 AM EST",
        "Jan 13, 1998 9:00 AM EST",
        "Jan 14, 1998 9:00 AM EST",
        "Jan 15, 1998 9:00 AM EST",
        "Jan 16, 1998 9:00 AM EST",
        "Jan 17, 1998 9:00 AM EST",
        "Jan 18, 1998 9:00 AM EST",
        "Jan 19, 1998 9:00 AM EST",
        "Jan 20, 1998 9:00 AM EST",
        "Jan 21, 1998 9:00 AM EST",
        "Jan 22, 1998 9:00 AM EST",
        "Jan 23, 1998 9:00 AM EST",
        "Jan 24, 1998 9:00 AM EST",
        "Jan 25, 1998 9:00 AM EST",
        "Jan 26, 1998 9:00 AM EST",
        "Jan 27, 1998 9:00 AM EST",
        "Jan 28, 1998 9:00 AM EST",
        "Jan 29, 1998 9:00 AM EST",
        "Jan 30, 1998 9:00 AM EST",
        "Jan 31, 1998 9:00 AM EST",
        "Jan 01, 1999 9:00 AM EST",
        "Jan 02, 1999 9:00 AM EST",
        "Jan 03, 1999 9:00 AM EST",
        "Jan 04, 1999 9:00 AM EST",
        "Jan 05, 1999 9:00 AM EST",
        "Jan 06, 1999 9:00 AM EST",
        "Jan 07, 1999 9:00 AM EST",
        "Jan 08, 1999 9:00 AM EST",
        "Jan 09, 1999 9:00 AM EST",
        "Jan 10, 1999 9:00 AM EST",
        "Jan 11, 1999 9:00 AM EST",
        "Jan 12, 1999 9:00 AM EST",
        "Jan 13, 1999 9:00 AM EST",
        "Jan 14, 1999 9:00 AM EST",
        "Jan 15, 1999 9:00 AM EST",
        "Jan 16, 1999 9:00 AM EST",
        "Jan 17, 1999 9:00 AM EST",
        "Jan 18, 1999 9:00 AM EST",
        "Jan 19, 1999 9:00 AM EST",
        "Jan 20, 1999 9:00 AM EST",
        "Jan 21, 1999 9:00 AM EST",
        "Jan 22, 1999 9:00 AM EST",
        "Jan 23, 1999 9:00 AM EST",
        "Jan 24, 1999 9:00 AM EST",
        "Jan 25, 1999 9:00 AM EST",
        "Jan 26, 1999 9:00 AM EST",
        "Jan 27, 1999 9:00 AM EST",
        "Jan 28, 1999 9:00 AM EST",
        "Jan 29, 1999 9:00 AM EST",
        "Jan 30, 1999 9:00 AM EST",
        "Jan 31, 1999 9:00 AM EST",
        "Jan 01, 2000 9:00 AM EST",
        "Jan 02, 2000 9:00 AM EST",
        "Jan 03, 2000 9:00 AM EST",
        "Jan 04, 2000 9:00 AM EST",
        "Jan 05, 2000 9:00 AM EST",
        "Jan 06, 2000 9:00 AM EST",
        "Jan 07, 2000 9:00 AM EST",
        "Jan 08, 2000 9:00 AM EST",
        "Jan 09, 2000 9:00 AM EST",
        "Jan 10, 2000 9:00 AM EST",
        "Jan 11, 2000 9:00 AM EST",
        "Jan 12, 2000 9:00 AM EST",
        "Jan 13, 2000 9:00 AM EST",
        "Jan 14, 2000 9:00 AM EST",
        "Jan 15, 2000 9:00 AM EST",
        "Jan 16, 2000 9:00 AM EST",
        "Jan 17, 2000 9:00 AM EST",
        "Jan 18, 2000 9:00 AM EST",
        "Jan 19, 2000 9:00 AM EST",
        "Jan 20, 2000 9:00 AM EST",
        "Jan 21, 2000 9:00 AM EST",
        "Jan 22, 2000 9:00 AM EST",
        "Jan 23, 2000 9:00 AM EST",
        "Jan 24, 2000 9:00 AM EST",
        "Jan 25, 2000 9:00 AM EST",
        "Jan 26, 2000 9:00 AM EST",
        "Jan 27, 2000 9:00 AM EST",
        "Jan 28, 2000 9:00 AM EST",
        "Jan 29, 2000 9:00 AM EST",
        "Jan 30, 2000 9:00 AM EST",
        "Jan 31, 2000 9:00 AM EST"
      ], true
      )
      
      enumeration_spec(
      "Weekly for 10 occurrences (RFC 2445 p 119)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=WEEKLY;COUNT=10",
      [
        "Sep 2, 1997 9:00 AM EDT",
        "Sep 9, 1997 9:00 AM EDT",
        "Sep 16, 1997 9:00 AM EDT",
        "Sep 23, 1997 9:00 AM EDT",
        "Sep 30, 1997 9:00 AM EDT",
        "Oct 7, 1997 9:00 AM EDT",
        "Oct 14, 1997 9:00 AM EDT",
        "Oct 21, 1997 9:00 AM EDT",
        "Oct 28, 1997 9:00 AM EST",
        "Nov 4, 1997 9:00 AM EST"
      ]
      )
      
      enumeration_spec(
      "Weekly until December 24, 1997 (RFC 2445 p 119)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=WEEKLY;UNTIL=19971224T000000Z",
      [
        "Sep 2, 1997 9:00 AM EDT",
        "Sep 9, 1997 9:00 AM EDT",
        "Sep 16, 1997 9:00 AM EDT",
        "Sep 23, 1997 9:00 AM EDT",
        "Sep 30, 1997 9:00 AM EDT",
        "Oct 7, 1997 9:00 AM EDT",
        "Oct 14, 1997 9:00 AM EDT",
        "Oct 21, 1997 9:00 AM EDT",
        "Oct 28, 1997 9:00 AM EST",
        "Nov 4, 1997 9:00 AM EST",
        "Nov 11, 1997 9:00 AM EST",
        "Nov 18, 1997 9:00 AM EST",
        "Nov 25, 1997 9:00 AM EST",
        "Dec 2, 1997 9:00 AM EST",
        "Dec 9, 1997 9:00 AM EST",
        "Dec 16, 1997 9:00 AM EST",
        "Dec 23, 1997 9:00 AM EST"
      ]
      )
      
      enumeration_spec(
      "Every other week - forever (RFC 2445 p 119)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=WEEKLY;INTERVAL=2;WKST=SU",
      [
        "Sep 2, 1997 9:00 AM EDT",
        "Sep 16, 1997 9:00 AM EDT",
        "Sep 30, 1997 9:00 AM EDT",
        "Oct 14, 1997 9:00 AM EDT",
        "Oct 28, 1997 9:00 AM EST",
        "Nov 11, 1997 9:00 AM EST",
        "Nov 25, 1997 9:00 AM EST",
        "Dec 9, 1997 9:00 AM EST",
        "Dec 23, 1997 9:00 AM EST",
        "Jan 6, 1998 9:00 AM EST",
        "Jan 20, 1998 9:00 AM EST",
        "Feb 3, 1998 9:00 AM EST",
        "..."
      ]
      )
      
      enumeration_spec(
      "Weekly on Tuesday and Thursday for 5 weeks, Alternative 1 (RFC 2445 p 119)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH",
      [
        "Sep 2, 1997 9:00 AM EDT",
        "Sep 4, 1997 9:00 AM EDT",
        "Sep 9, 1997 9:00 AM EDT",
        "Sep 11, 1997 9:00 AM EDT",
        "Sep 16, 1997 9:00 AM EST",
        "Sep 18, 1997 9:00 AM EST",
        "Sep 23, 1997 9:00 AM EST",
        "Sep 25, 1997 9:00 AM EST",
        "Sep 30, 1997 9:00 AM EST",
        "Oct 2, 1997 9:00 AM EST"
      ]
      )
      
      enumeration_spec(
      "Weekly on Tuesday and Thursday for 5 weeks, Alternative 2 (RFC 2445 p 120)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=WEEKLY;COUNT=10;WKST=SU;BYDAY=TU,TH",
      [
        "Sep 2, 1997 9:00 AM EDT",
        "Sep 4, 1997 9:00 AM EDT",
        "Sep 9, 1997 9:00 AM EDT",
        "Sep 11, 1997 9:00 AM EDT",
        "Sep 16, 1997 9:00 AM EST",
        "Sep 18, 1997 9:00 AM EST",
        "Sep 23, 1997 9:00 AM EST",
        "Sep 25, 1997 9:00 AM EST",
        "Sep 30, 1997 9:00 AM EST",
        "Oct 2, 1997 9:00 AM EST"
      ]
      )
      
      enumeration_spec(
      "Every other week on Monday, Wednesday and Friday until December 24,1997, but starting on Tuesday, September 2, 1997 (RFC 2445 p 120)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;BYDAY=MO,WE,FR",
      [
        "Sep 2, 1997 9:00 AM EDT",
        "Sep 3, 1997 9:00 AM EDT",
        "Sep 5, 1997 9:00 AM EDT",
        "Sep 15, 1997 9:00 AM EDT",
        "Sep 17, 1997 9:00 AM EDT",
        "Sep 19, 1997 9:00 AM EDT",
        "Sep 29, 1997 9:00 AM EDT",
        "Oct 1, 1997 9:00 AM EDT",
        "Oct 3, 1997 9:00 AM EDT",
        "Oct 13, 1997 9:00 AM EDT",
        "Oct 15, 1997 9:00 AM EDT",
        "Oct 17, 1997 9:00 AM EDT",
        "Oct 27, 1997 9:00 AM EST",
        "Oct 29, 1997 9:00 AM EST",
        "Oct 31, 1997 9:00 AM EST",
        "Nov 10, 1997 9:00 AM EST",
        "Nov 12, 1997 9:00 AM EST",
        "Nov 14, 1997 9:00 AM EST",
        "Nov 24, 1997 9:00 AM EST",
        "Nov 26, 1997 9:00 AM EST",
        "Nov 28, 1997 9:00 AM EST",
        "Dec 8, 1997 9:00 AM EST",
        "Dec 10, 1997 9:00 AM EST",
        "Dec 12, 1997 9:00 AM EST",
        "Dec 22, 1997 9:00 AM EST"
      ], true
      )
      
      enumeration_spec(
      "Every other week on TU and TH for 8 occurrences (RFC 2445 p 120)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH",
      [
        "Sep 2, 1997 9:00 AM EDT",
        "Sep 4, 1997 9:00 AM EDT",
        "Sep 16, 1997 9:00 AM EDT",
        "Sep 18, 1997 9:00 AM EDT",
        "Sep 30, 1997 9:00 AM EDT",
        "Oct 2, 1997 9:00 AM EDT",
        "Oct 14, 1997 9:00 AM EDT",
        "Oct 16, 1997 9:00 AM EDT"
      ], true
      )
      
      enumeration_spec(
      "Monthly on the 1st Friday for ten occurrences (RFC 2445 p 120)",
      "19970905T090000",
      "US-Eastern",
      "FREQ=MONTHLY;COUNT=10;BYDAY=1FR",
      [
        "Sep 5, 1997 9:00 AM EDT",
        "Oct 3, 1997 9:00 AM EDT",
        "Nov 7, 1997 9:00 AM EST",
        "Dec 5, 1997 9:00 AM EST",
        "Jan 2, 1998 9:00 AM EST",
        "Feb 6, 1998 9:00 AM EST",
        "Mar 6, 1998 9:00 AM EST",
        "Apr 3, 1998 9:00 AM EST",
        "May 1, 1998 9:00 AM EDT",
        "Jun 5, 1998 9:00 AM EDT",
      ]
      )
      
      enumeration_spec(
      "Monthly on the 1st Friday until December 24, 1997 (RFC 2445 p 120)",
      "19970905T090000",
      "US-Eastern",
      "FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR",
      [
        "Sep 5, 1997 9:00 AM EDT",
        "Oct 3, 1997 9:00 AM EDT",
        "Nov 7, 1997 9:00 AM EST",
        "Dec 5, 1997 9:00 AM EST"
      ]
      )
      
      enumeration_spec(
      "Every other month on the 1st and last Sunday of the month for 10 occurrences (RFC 2445 p 120)",
      "19970907T090000",
      "US-Eastern",
      "FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU",
      [
        "Sep 7, 1997 9:00 AM EDT",
        "Sep 28, 1997 9:00 AM EDT",
        "Nov 2, 1997 9:00 AM EST",
        "Nov 30, 1997 9:00 AM EST",
        "Jan 4, 1998 9:00 AM EST",
        "Jan 25, 1998 9:00 AM EST",
        "Mar 1, 1998 9:00 AM EST",
        "Mar 29, 1998 9:00 AM EST",
        "May 3, 1998 9:00 AM EDT",
        "May 31, 1998 9:00 AM EST"
      ]
      )
      
      enumeration_spec(
      "Monthly on the second to last Monday of the month for 6 months (RFC 2445 p 121)",
      "19970922T090000",
      "US-Eastern",
      "FREQ=MONTHLY;COUNT=6;BYDAY=-2MO",
      [
        "Sep 22, 1997 9:00 AM EDT",
        "Oct 20, 1997 9:00 AM EDT",
        "Nov 17, 1997 9:00 AM EST",
        "Dec 22, 1997 9:00 AM EST",
        "Jan 19, 1998 9:00 AM EST",
        "Feb 16, 1998 9:00 AM EST"
      ]
      )
      
      enumeration_spec(
      "Monthly on the third the to last day of the month forever (RFC 2445 p 121)",
      "19970928T090000",
      "US-Eastern",
      "FREQ=MONTHLY;BYMONTHDAY=-3",
      [
        "Sep 28, 1997 9:00 AM EDT",
        "Oct 29, 1997 9:00 AM EDT",
        "Nov 28, 1997 9:00 AM EST",
        "Dec 29, 1997 9:00 AM EST",
        "Jan 29, 1998 9:00 AM EST",
        "Feb 26, 1998 9:00 AM EST",
        "..."
      ]
      )
      
      enumeration_spec(
      "Monthly on the first and last day of the month for 10 occurrences (RFC 2445 p 121)",
      "19970930T090000",
      "US-Eastern",
      "FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1",
      [
        "Sep 30, 1997 9:00 AM EDT",
        "Oct 1, 1997 9:00 AM EDT",
        "Oct 31, 1997 9:00 AM EST",
        "Nov 1, 1997 9:00 AM EST",
        "Nov 30, 1997 9:00 AM EST",
        "Dec 1, 1997 9:00 AM EST",
        "Dec 31, 1997 9:00 AM EST",
        "Jan 1, 1998 9:00 AM EST",
        "Jan 31, 1998 9:00 AM EST",
        "Feb 1, 1998 9:00 AM EST"
      ]
      )
      
      enumeration_spec(
      "Every 18 months on the 10th thru 15th of the month for 10 occurrences (RFC 2445 p 121)",
      "19970910T090000",
      "US-Eastern",
      "FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,15",
      [
        "Sep 10, 1997 9:00 AM EDT",
        "Sep 11, 1997 9:00 AM EDT",
        "Sep 12, 1997 9:00 AM EDT",
        "Sep 13, 1997 9:00 AM EDT",
        "Sep 14, 1997 9:00 AM EDT",
        "Sep 15, 1997 9:00 AM EDT",
        "Mar 10, 1999 9:00 AM EDT",
        "Mar 11, 1999 9:00 AM EDT",
        "Mar 12, 1999 9:00 AM EDT",
        "Mar 13, 1999 9:00 AM EDT"
      ]
      )
      
      enumeration_spec(
      "Every Tuesday, every other month (RFC 2445 p 122)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=MONTHLY;INTERVAL=2;BYDAY=TU",
      [
        "Sep 2, 1997 9:00 AM EDT",
        "Sep 9, 1997 9:00 AM EDT",
        "Sep 16, 1997 9:00 AM EDT",
        "Sep 23, 1997 9:00 AM EDT",
        "Sep 30, 1997 9:00 AM EDT",
        "Nov 4, 1997 9:00 AM EST",
        "Nov 11, 1997 9:00 AM EST",
        "Nov 18, 1997 9:00 AM EST",
        "Nov 25, 1997 9:00 AM EST",
        "Jan 6, 1998 9:00 AM EST",
        "Jan 13, 1998 9:00 AM EST",
        "Jan 20, 1998 9:00 AM EST",
        "Jan 27, 1998 9:00 AM EST",
        "Mar 3, 1998 9:00 AM EST",
        "Mar 10, 1998 9:00 AM EST",
        "Mar 17, 1998 9:00 AM EST",
        "Mar 24, 1998 9:00 AM EST",
        "Mar 31, 1998 9:00 AM EST",
        "..."
      ]
      )
      
      enumeration_spec(
      "Yearly in June and July for 10 occurrences (RFC 2445 p 122)",
      "19970610T090000",
      "US-Eastern",
      "FREQ=YEARLY;COUNT=10;BYMONTH=6,7",
      [
        "Jun 10, 1997 9:00 AM EDT",
        "Jul 10, 1997 9:00 AM EDT",
        "Jun 10, 1998 9:00 AM EDT",
        "Jul 10, 1998 9:00 AM EDT",
        "Jun 10, 1999 9:00 AM EDT",
        "Jul 10, 1999 9:00 AM EDT",
        "Jun 10, 2000 9:00 AM EDT",
        "Jul 10, 2000 9:00 AM EDT",
        "Jun 10, 2001 9:00 AM EDT",
        "Jul 10, 2001 9:00 AM EDT"
      ]
      )
      
      enumeration_spec(
      "Every other year on January, February, and March for 10 occurrences (RFC 2445 p 122)",
      "19970310T090000",
      "US-Eastern",
      "FREQ=YEARLY;INTERVAL=2;COUNT=10;BYMONTH=1,2,3",
      [
        "Mar 10, 1997 9:00 AM EST",
        "Jan 10, 1999 9:00 AM EST",
        "Feb 10, 1999 9:00 AM EST",
        "Mar 10, 1999 9:00 AM EST",
        "Jan 10, 2001 9:00 AM EST",
        "Feb 10, 2001 9:00 AM EST",
        "Mar 10, 2001 9:00 AM EST",
        "Jan 10, 2003 9:00 AM EST",
        "Feb 10, 2003 9:00 AM EST",
        "Mar 10, 2003 9:00 AM EST",
      ]
      )
      
      enumeration_spec(
      "Every 3rd year on the 1st, 100th and 200th day for 10 occurrences (RFC 2445 p 122)",
      "19970101T090000",
      "US-Eastern",
      "FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200",
      [
        "Jan 1, 1997 9:00 AM EST",
        "Apr 10, 1997 9:00 AM EDT",
        "Jul 19, 1997 9:00 AM EDT",
        "Jan 1, 2000 9:00 AM EST",
        "Apr 9, 2000 9:00 AM EDT",
        "Jul 18, 2000 9:00 AM EDT",
        "Jan 1, 2003 9:00 AM EST",
        "Apr 10, 2003 9:00 AM EDT",
        "Jul 19, 2003 9:00 AM EDT",
        "Jan 1, 2006 9:00 AM EST"
      ]
      )
      
      enumeration_spec(
      "Every 20th Monday of the year, forever (RFC 2445 p 122-3)",
      "19970519T090000",
      "US-Eastern",
      "FREQ=YEARLY;BYDAY=20MO",
      [
        "May 19, 1997 9:00 AM EDT",
        "May 18, 1998 9:00 AM EDT",
        "May 17, 1999 9:00 AM EDT",
        "..."
      ]
      )
      
      enumeration_spec(
      "Every second to last Wednesday of the year, forever",
      "19971224T090000",
      "US-Eastern",
      "FREQ=YEARLY;BYDAY=-2WE",
      [
        "Dec 24, 1997 9:00 AM EDT",
        "Dec 23, 1998 9:00 AM EDT",
        "Dec 22, 1999 9:00 AM EDT",
        "Dec 20, 2000 9:00 AM EDT",
        "..."
      ]
      )
      
      enumeration_spec(
      "Monday of week number 20 (where the default start of the week is Monday), forever (RFC 2445 p 123)",
      "19970512T090000",
      "US-Eastern",
      "FREQ=YEARLY;BYWEEKNO=20;BYDAY=MO",
      [
        "May 12, 1997 9:00 AM EDT",
        "May 11, 1998 9:00 AM EDT",
        "May 17, 1999 9:00 AM EDT",
        "..."
      ]
      )
      
      enumeration_spec(
      "Every Thursday in March, forever (RFC 2445 p 123)",
      "19970313T090000",
      "US-Eastern",
      "FREQ=YEARLY;BYMONTH=3;BYDAY=TH",
      [
        "Mar 13, 1997 9:00 AM EST",
        "Mar 20, 1997 9:00 AM EST",
        "Mar 27, 1997 9:00 AM EST",
        "Mar 5, 1998 9:00 AM  EST",
        "Mar 12, 1998 9:00 AM EST",
        "Mar 19, 1998 9:00 AM EST",
        "Mar 26, 1998 9:00 AM EST",
        "Mar 4, 1999 9:00 AM  EST",
        "Mar 11, 1999 9:00 AM EST",
        "Mar 18, 1999 9:00 AM EST",
        "Mar 25, 1999 9:00 AM EST",
        "..."
      ]
      )
      
      enumeration_spec(
      "Every Thursday, but only during June, July, and August, forever (RFC 2445 p 123)",
      "19970605T090000",
      "US-Eastern",
      "FREQ=YEARLY;BYDAY=TH;BYMONTH=6,7,8",
      [
        "Jun 05, 1997 9:00 AM EDT",
        "Jun 12, 1997 9:00 AM EDT",
        "Jun 19, 1997 9:00 AM EDT",
        "Jun 26, 1997 9:00 AM EDT",
        "Jul 03, 1997 9:00 AM EDT",
        "Jul 10, 1997 9:00 AM EDT",
        "Jul 17, 1997 9:00 AM EDT",
        "Jul 24, 1997 9:00 AM EDT",
        "Jul 31, 1997 9:00 AM EDT",
        "Aug 07, 1997 9:00 AM EDT",
        "Aug 14, 1997 9:00 AM EDT",
        "Aug 21, 1997 9:00 AM EDT",
        "Aug 28, 1997 9:00 AM EDT",
        "Jun 04, 1998 9:00 AM EDT",
        "Jun 11, 1998 9:00 AM EDT",
        "Jun 18, 1998 9:00 AM EDT",
        "Jun 25, 1998 9:00 AM EDT",
        "Jul 02, 1998 9:00 AM EDT",
        "Jul 09, 1998 9:00 AM EDT",
        "Jul 16, 1998 9:00 AM EDT",
        "Jul 23, 1998 9:00 AM EDT",
        "Jul 30, 1998 9:00 AM EDT",
        "Aug 06, 1998 9:00 AM EDT",
        "Aug 13, 1998 9:00 AM EDT",
        "Aug 20, 1998 9:00 AM EDT",
        "Aug 27, 1998 9:00 AM EDT",
        "Jun 03, 1999 9:00 AM EDT",
        "Jun 10, 1999 9:00 AM EDT",
        "Jun 17, 1999 9:00 AM EDT",
        "Jun 24, 1999 9:00 AM EDT",
        "Jul 01, 1999 9:00 AM EDT",
        "Jul 08, 1999 9:00 AM EDT",
        "Jul 15, 1999 9:00 AM EDT",
        "Jul 22, 1999 9:00 AM EDT",
        "Jul 29, 1999 9:00 AM EDT",
        "Aug 05, 1999 9:00 AM EDT",
        "Aug 12, 1999 9:00 AM EDT",
        "Aug 19, 1999 9:00 AM EDT",
        "Aug 26, 1999 9:00 AM EDT",
        "..."
      ]
      )
      
      enumeration_spec(
      "Every Friday the 13th, forever (RFC 2445 p 123-4)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13",
      [
        # The RFC example uses exdate to exclude the start date, this is a slightly altered
        # use case
        "Sep 2, 1997 9:00 AM EST",
        "Feb 13, 1998 9:00 AM EST",
        "Mar 13, 1998 9:00 AM EST",
        "Nov 13, 1998 9:00 AM EST",
        "Aug 13, 1999 9:00 AM EDT",
        "Oct 13, 2000 9:00 AM EST",
        "..."
      ]
      )
      
      enumeration_spec(
      "The first Saturday that follows the first Sunday of the month, forever (RFC 2445 p 124)",
      "19970913T090000",
      "US-Eastern",
      "FREQ=MONTHLY;BYDAY=SA;BYMONTHDAY=7,8,9,10,11,12,13",
      [
        "Sep 13, 1997 9:00 AM EDT",
        "Oct 11, 1997 9:00 AM EDT",
        "Nov 8, 1997 9:00 AM EST",
        "Dec 13, 1997 9:00 AM EST",
        "Jan 10, 1998 9:00 AM EST",
        "Feb 7, 1998 9:00 AM EST",
        "Mar 7, 1998 9:00 AM EST",
        "Apr 11, 1998 9:00 AM EDT",
        "May 9, 1998 9:00 AM EDT",
        "Jun 13, 1998 9:00 AM EDT",
        "..."
      ]
      )
      
      enumeration_spec(
      "Every four years, the first Tuesday after a Monday in November, forever(U.S. Presidential Election day) (RFC 2445 p 124)",
      "19961105T090000",
      "US-Eastern",
      "FREQ=YEARLY;INTERVAL=4;BYMONTH=11;BYDAY=TU;BYMONTHDAY=2,3,4,5,6,7,8",
      [
        "Nov 5, 1996 9:00 AM EDT",
        "Nov 7, 2000 9:00 AM EDT",
        "Nov 2, 2004 9:00 AM EDT",
        "..."
      ]
      )
      
      enumeration_spec(
      "3rd instance into the month of one of Tuesday, Wednesday or Thursday, for the next 3 months (RFC 2445 p 124)",
      "19970904T090000",
      "US-Eastern",
      "FREQ=MONTHLY;COUNT=3;BYDAY=TU,WE,TH;BYSETPOS=3",
      [
        "Sep 4, 1997 9:00 AM EDT",
        "Oct 7, 1997 9:00 AM EDT",
        "Nov 6, 1997 9:00 AM EST",
      ]
      )
      
      enumeration_spec(
      "The 2nd to last weekday of the month (RFC 2445 p 124)",
      "19970929T090000",
      "US-Eastern",
      "FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-2",
      [
        "Sep 29, 1997 9:00 AM EDT",
        "Oct 30, 1997 9:00 AM EST",
        "Nov 27, 1997 9:00 AM EST",
        "Dec 30, 1997 9:00 AM EST",
        "Jan 29, 1998 9:00 AM EST",
        "Feb 26, 1998 9:00 AM EST",
        "Mar 30, 1998 9:00 AM EST",
        "..."
      ]
      )
      
      enumeration_spec(
      "Every 3 hours from 9:00 AM to 5:00 PM on a specific day (RFC 2445 p 125)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=HOURLY;INTERVAL=3;UNTIL=19970902T170000Z",
      [
        "Sep 2, 1997 9:00 EDT",
        "Sep 2, 1997 12:00 EDT",
        "Sep 2, 1997 15:00 EDT",
      ]
      )
      
      enumeration_spec(
      "Every 15 minutes for 6 occurrences (RFC 2445 p 125)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=MINUTELY;INTERVAL=15;COUNT=6",
      [
        "Sep 2, 1997 09:00 EDT",
        "Sep 2, 1997 09:15 EDT",
        "Sep 2, 1997 09:30 EDT",
        "Sep 2, 1997 09:45 EDT",
        "Sep 2, 1997 10:00 EDT",
        "Sep 2, 1997 10:15 EDT",
      ]
      )
      
      enumeration_spec(
      "Every hour and a half for 4 occurrences (RFC 2445 p 125)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=MINUTELY;INTERVAL=90;COUNT=4",
      [
        "Sep 2, 1997 09:00 EDT",
        "Sep 2, 1997 10:30 EDT",
        "Sep 2, 1997 12:00 EDT",
        "Sep 2, 1997 13:30 EDT",
      ]
      )
      
      enumeration_spec(
      "Every 20 minutes from 9:00 AM to 4:40 PM every day - alternative 1 (RFC 2445 p 125)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=DAILY;BYHOUR=9,10,11,12,13,14,15,16;BYMINUTE=0,20,40",
      [
        "Sep 2, 1997 09:00 EDT",
        "Sep 2, 1997 09:20 EDT",
        "Sep 2, 1997 09:40 EDT",
        "Sep 2, 1997 10:00 EDT",
        "Sep 2, 1997 10:20 EDT",
        "Sep 2, 1997 10:40 EDT",
        "Sep 2, 1997 11:00 EDT",
        "Sep 2, 1997 11:20 EDT",
        "Sep 2, 1997 11:40 EDT",
        "Sep 2, 1997 12:00 EDT",
        "Sep 2, 1997 12:20 EDT",
        "Sep 2, 1997 12:40 EDT",
        "Sep 2, 1997 13:00 EDT",
        "Sep 2, 1997 13:20 EDT",
        "Sep 2, 1997 13:40 EDT",
        "Sep 2, 1997 14:00 EDT",
        "Sep 2, 1997 14:20 EDT",
        "Sep 2, 1997 14:40 EDT",
        "Sep 2, 1997 15:00 EDT",
        "Sep 2, 1997 15:20 EDT",
        "Sep 2, 1997 15:40 EDT",
        "Sep 2, 1997 16:00 EDT",
        "Sep 2, 1997 16:20 EDT",
        "Sep 2, 1997 16:40 EDT",
        "Sep 3, 1997 09:00 EDT",
        "Sep 3, 1997 09:20 EDT",
        "Sep 3, 1997 09:40 EDT",
        "Sep 3, 1997 10:00 EDT",
        "Sep 3, 1997 10:20 EDT",
        "Sep 3, 1997 10:40 EDT",
        "Sep 3, 1997 11:00 EDT",
        "Sep 3, 1997 11:20 EDT",
        "Sep 3, 1997 11:40 EDT",
        "Sep 3, 1997 12:00 EDT",
        "Sep 3, 1997 12:20 EDT",
        "Sep 3, 1997 12:40 EDT",
        "Sep 3, 1997 13:00 EDT",
        "Sep 3, 1997 13:20 EDT",
        "Sep 3, 1997 13:40 EDT",
        "Sep 3, 1997 14:00 EDT",
        "Sep 3, 1997 14:20 EDT",
        "Sep 3, 1997 14:40 EDT",
        "Sep 3, 1997 15:00 EDT",
        "Sep 3, 1997 15:20 EDT",
        "Sep 3, 1997 15:40 EDT",
        "Sep 3, 1997 16:00 EDT",
        "Sep 3, 1997 16:20 EDT",
        "Sep 3, 1997 16:40 EDT",
        "..."
      ]
      )
      
      enumeration_spec(
      "Every 20 minutes from 9:00 AM to 4:40 PM every day - alternative 2 (RFC 2445 p 125)",
      "19970902T090000",
      "US-Eastern",
      "FREQ=MINUTELY;INTERVAL=20;BYHOUR=9,10,11,12,13,14,15,16",
      [
        "Sep 2, 1997 09:00 EDT",
        "Sep 2, 1997 09:20 EDT",
        "Sep 2, 1997 09:40 EDT",
        "Sep 2, 1997 10:00 EDT",
        "Sep 2, 1997 10:20 EDT",
        "Sep 2, 1997 10:40 EDT",
        "Sep 2, 1997 11:00 EDT",
        "Sep 2, 1997 11:20 EDT",
        "Sep 2, 1997 11:40 EDT",
        "Sep 2, 1997 12:00 EDT",
        "Sep 2, 1997 12:20 EDT",
        "Sep 2, 1997 12:40 EDT",
        "Sep 2, 1997 13:00 EDT",
        "Sep 2, 1997 13:20 EDT",
        "Sep 2, 1997 13:40 EDT",
        "Sep 2, 1997 14:00 EDT",
        "Sep 2, 1997 14:20 EDT",
        "Sep 2, 1997 14:40 EDT",
        "Sep 2, 1997 15:00 EDT",
        "Sep 2, 1997 15:20 EDT",
        "Sep 2, 1997 15:40 EDT",
        "Sep 2, 1997 16:00 EDT",
        "Sep 2, 1997 16:20 EDT",
        "Sep 2, 1997 16:40 EDT",
        "Sep 3, 1997 09:00 EDT",
        "Sep 3, 1997 09:20 EDT",
        "Sep 3, 1997 09:40 EDT",
        "Sep 3, 1997 10:00 EDT",
        "Sep 3, 1997 10:20 EDT",
        "Sep 3, 1997 10:40 EDT",
        "Sep 3, 1997 11:00 EDT",
        "Sep 3, 1997 11:20 EDT",
        "Sep 3, 1997 11:40 EDT",
        "Sep 3, 1997 12:00 EDT",
        "Sep 3, 1997 12:20 EDT",
        "Sep 3, 1997 12:40 EDT",
        "Sep 3, 1997 13:00 EDT",
        "Sep 3, 1997 13:20 EDT",
        "Sep 3, 1997 13:40 EDT",
        "Sep 3, 1997 14:00 EDT",
        "Sep 3, 1997 14:20 EDT",
        "Sep 3, 1997 14:40 EDT",
        "Sep 3, 1997 15:00 EDT",
        "Sep 3, 1997 15:20 EDT",
        "Sep 3, 1997 15:40 EDT",
        "Sep 3, 1997 16:00 EDT",
        "Sep 3, 1997 16:20 EDT",
        "Sep 3, 1997 16:40 EDT",
        "..."
      ]
      )
      
      enumeration_spec(
      "An example where the days generated makes a difference because of WKST (MO case) (RFC 2445 p 125)",
      "19970805T090000",
      "US-Eastern",
      "FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=MO",
      [
        "Aug 05, 1997 09:00 EDT",
        "Aug 10, 1997 09:00 EDT",
        "Aug 19, 1997 09:00 EDT",
        "Aug 24, 1997 09:00 EDT"
      ]
      )
      
      enumeration_spec(
      "An example where the days generated makes a difference because of WKST (MO case) (RFC 2445 p 125)",
      "19970805T090000",
      "US-Eastern",
      "FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=SU",
      [
        "Aug 05, 1997 09:00 EDT",
        "Aug 17, 1997 09:00 EDT",
        "Aug 19, 1997 09:00 EDT",
        "Aug 31, 1997 09:00 EDT"
      ]
      )
    end
  end

describe RiCal::PropertyValue::RecurrenceRule::RecurringDay do
  
  def recurring(day)
    RiCal::PropertyValue::RecurrenceRule::RecurringDay.new(day, RiCal::PropertyValue::RecurrenceRule.new(nil, :value => "FREQ=MONTHLY"))
  end
    
  describe "MO - any monday" do
    before(:each) do
      @it= recurring("MO")
    end

    it "should include all Mondays" do
      [1, 8, 15, 22, 29].each do | day |
        @it.should include(Date.parse("Dec #{day} 2008"))
      end
    end

    it "should not include non-Mondays" do
      (9..14).each do | day |
        @it.should_not include(Date.parse("Dec #{day} 2008"))
      end
    end
  end

  describe "TU - any Tuesday" do
    before(:each) do
      @it= recurring("TU")
    end

    it "should include all Tuesdays" do
      [2, 9, 16, 23, 30].each do | day |
        @it.should include(Date.parse("Dec #{day} 2008"))
      end
    end

    it "should not include non-Tuesdays" do
      (10..15).each do | day |
        @it.should_not include(Date.parse("Dec #{day} 2008"))
      end
    end
  end

  describe "WE - any Wednesday" do
    before(:each) do
      @it= recurring("WE")
    end

    it "should include all Wednesdays" do
      [3, 10, 17, 24, 31].each do | day |
        @it.should include(Date.parse("Dec #{day} 2008"))
      end
    end

    it "should not include non-Wednesdays" do
      (11..16).each do | day |
        @it.should_not include(Date.parse("Dec #{day} 2008"))
      end
    end
  end

  describe "TH - any Thursday" do
    before(:each) do
      @it= recurring("TH")
    end

    it "should include all Thursdays" do
      [4, 11, 18, 25].each do | day |
        @it.should include(Date.parse("Dec #{day} 2008"))
      end
    end

    it "should not include non-Thursdays" do
      (5..10).each do | day |
        @it.should_not include(Date.parse("Dec #{day} 2008"))
      end
    end
  end

  describe "FR - any Friday" do
    before(:each) do
      @it= recurring("FR")
    end

    it "should include all Fridays" do
      [5, 12, 19, 26].each do | day |
        @it.should include(Date.parse("Dec #{day} 2008"))
      end
    end

    it "should not include non-Fridays" do
      (6..11).each do | day |
        @it.should_not include(Date.parse("Dec #{day} 2008"))
      end
    end
  end

  describe "SA - any Saturday" do
    before(:each) do
      @it= recurring("SA")
    end

    it "should include all Saturdays" do
      [6, 13, 20, 27].each do | day |
        @it.should include(Date.parse("Dec #{day} 2008"))
      end
    end

    it "should not include non-Saturdays" do
      (7..12).each do | day |
        @it.should_not include(Date.parse("Dec #{day} 2008"))
      end
    end
  end

  describe "SU - any Sunday" do
    before(:each) do
      @it= recurring("SU")
    end

    it "should include all Sundays" do
      [7, 14, 21, 28].each do | day |
        @it.should include(Date.parse("Dec #{day} 2008"))
      end
    end

    it "should not include non-Saturdays" do
      (8..13).each do | day |
        @it.should_not include(Date.parse("Dec #{day} 2008"))
      end
    end
  end

  describe "1MO - first Monday" do
    before(:each) do
      @it = recurring("1MO")
    end

    it "should match the first Monday of the month" do
      @it.should include(Date.parse("Nov 3 2008"))
    end

    it "should not include other Mondays" do
      [10, 17, 24].each do |day|
        @it.should_not include(Date.parse("Nov #{day} 2008"))
      end
    end
  end

  describe "5MO - Fifth Monday" do
    before(:each) do
      @it = recurring("5MO")
    end

    it "should match the fifth Monday of a month with five Mondays" do
      @it.should include(Date.parse("Dec 29 2008"))
    end
  end

  describe "-1MO - last Monday" do
    before(:each) do
      @it = recurring("-1MO")
    end

    it "should match the last Monday of the month" do
      @it.should include(Date.parse("Dec 29 2008"))
    end

    it "should not include other Mondays" do
      [1, 8, 15, 22].each do |day|
        @it.should_not include(Date.parse("Dec #{day} 2008"))
      end
    end

    it "should match February 28 for a non leap year when appropriate" do
      @it.should include(Date.parse("Feb 28 2005"))
    end

    it "should match February 29 for a non leap year when appropriate" do
      @it.should include(Date.parse("Feb 29 1988"))
    end
  end
end

describe RiCal::PropertyValue::RecurrenceRule::RecurringMonthDay do

  describe "with a value of 1" do
    before(:each) do
      @it = RiCal::PropertyValue::RecurrenceRule::RecurringMonthDay.new(1)
    end

    it "should match the first of each month" do
      (1..12).each do |month|
        @it.should include(Date.new(2008, month, 1))
      end
    end

    it "should not match other days of the month" do
        (2..31).each do |day|
          @it.should_not include(Date.new(2008, 1, day))
        end
      end

      describe "with a value of -1" do
        before(:each) do
          @it = RiCal::PropertyValue::RecurrenceRule::RecurringMonthDay.new(-1)
        end

        it "should match the last of each month" do
          {
            1 => 31, 2 => 29, 3 => 31, 4 => 30, 5 => 31, 6 => 30, 7 => 31,
            8 => 31, 9 => 30, 10 => 31, 11 => 30, 12 => 31
            }.each do |month, last|
              @it.should include(Date.new(2008, month, last))
          end
          @it.should include(Date.new(2007, 2, 28))
        end

        it "should not match other days of the month" do
            (1..30).each do |day|
              @it.should_not include(Date.new(2008, 1, day))
            end
          end
      end
  end
end

describe RiCal::PropertyValue::RecurrenceRule::RecurringYearDay do

  describe "with a value of 20" do
    before(:each) do
      @it = RiCal::PropertyValue::RecurrenceRule::RecurringYearDay.new(20)
    end

    it "should include January 20 in a non-leap year" do
      @it.should include(Date.new(2007, 1, 20))
    end

    it "should include January 20 in a leap year" do
      @it.should include(Date.new(2008, 1, 20))
    end
  end

  describe "with a value of 60" do
    before(:each) do
      @it = RiCal::PropertyValue::RecurrenceRule::RecurringYearDay.new(60)
    end

    it "should include March 1 in a non-leap year" do
      @it.should include(Date.new(2007, 3, 1))
    end

    it "should include February 29 in a leap year" do
      @it.should include(Date.new(2008, 2, 29))
    end
  end

  describe "with a value of -1" do
    before(:each) do
      @it = RiCal::PropertyValue::RecurrenceRule::RecurringYearDay.new(-1)
    end

    it "should include December 31 in a non-leap year" do
      @it.should include(Date.new(2007,12, 31))
    end

    it "should include December 31 in a leap year" do
      @it.should include(Date.new(2008,12, 31))
    end
  end

  describe "with a value of -365" do
    before(:each) do
      @it = RiCal::PropertyValue::RecurrenceRule::RecurringYearDay.new(-365)
    end

    it "should include January 1 in a non-leap year" do
      @it.should include(Date.new(2007,1, 1))
    end

    it "should include January 2 in a leap year" do
      @it.should include(Date.new(2008,1, 2))
    end
  end

  describe "with a value of -366" do
    before(:each) do
      @it = RiCal::PropertyValue::RecurrenceRule::RecurringYearDay.new(-366)
    end

    it "should not include January 1 in a non-leap year" do
      @it.should_not include(Date.new(2007,1, 1))
    end

    it "should include January 1 in a leap year" do
      @it.should include(Date.new(2008,1, 1))
    end
  end
end

describe RiCal::PropertyValue::RecurrenceRule::RecurringNumberedWeek do
  before(:each) do
    @it = RiCal::PropertyValue::RecurrenceRule::RecurringNumberedWeek.new(50)
  end
  
  it "should not include Dec 10, 2000" do
    @it.should_not include(Date.new(2000, 12, 10))
  end
  
  it "should include Dec 11, 2000" do
    @it.should include(Date.new(2000, 12, 11))
  end
  
  it "should include Dec 17, 2000" do
    @it.should include(Date.new(2000, 12, 17))
  end
  
  it "should not include Dec 18, 2000" do
    @it.should_not include(Date.new(2000, 12, 18))
  end
end
