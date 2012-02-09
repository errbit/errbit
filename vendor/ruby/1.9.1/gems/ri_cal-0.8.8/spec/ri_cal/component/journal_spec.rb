#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe RiCal::Component::Journal do
  
  describe ".entity_name" do
    it "should be VJOURNAL" do
      RiCal::Component::Journal.entity_name.should == "VJOURNAL"
    end
  end
  
  context ".start_time" do
    it "should be the same as dtstart for a date time" do
      event = RiCal.Journal {|e| e.dtstart = "20090525T151900"}
      event.start_time.should == DateTime.civil(2009,05,25,15,19,0,0)
    end
    
    it "should be the start of the day of dtstart for a date" do
      event = RiCal.Journal {|e| e.dtstart = "20090525"}
      event.start_time.should == DateTime.civil(2009,05,25,0,0,0,0)
    end
  end
  
  context ".finish_time" do
    it "should be the same as dtstart for a date time" do
      event = RiCal.Journal {|e| e.dtstart = "20090525T151900"}
      event.finish_time.should == DateTime.civil(2009,05,25,15,19,0,0)
    end
    
    it "should be the start of the day of dtstart for a date" do
      event = RiCal.Journal {|e| e.dtstart = "20090525"}
      event.finish_time.should == DateTime.civil(2009,05,25,0,0,0,0)
    end
  end
  
end
