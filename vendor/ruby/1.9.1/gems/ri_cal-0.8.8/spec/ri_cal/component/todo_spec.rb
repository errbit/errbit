#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe RiCal::Component::Todo do
  
  context ".start_time" do
    it "should be the same as dtstart for a date time" do
      todo = RiCal.Todo {|e| e.dtstart = "20090525T151900"}
      todo.start_time.should == DateTime.civil(2009,05,25,15,19,0,0)
    end
    
    it "should be the start of the day of dtstart for a date" do
      todo = RiCal.Todo {|e| e.dtstart = "20090525"}
      todo.start_time.should == DateTime.civil(2009,05,25,0,0,0,0)
    end
    
    it "should be nil if the dtstart property is not set" do
      RiCal.Todo.start_time.should be_nil
    end
  end
  
  context ".finish_time" do
    before(:each) do
      @todo = RiCal.Todo {|t| t.dtstart = "20090525T151900"}
    end

    context "with a given due" do
      it "should be the same as due for a date time" do
        @todo.due = "20090525T161900"
        @todo.finish_time.should == DateTime.civil(2009,05,25,16,19,0,0)
      end
    end

    context "with no due" do
      context "and a duration" do
        before(:each) do
          @todo.duration = "+PT1H"
        end
        
        it "should be the dtstart plus the duration" do
          @todo.finish_time.should == DateTime.civil(2009,5,25,16,19,0,0)
        end
        
        it "should be nil if the dtstart property is not set" do
          @todo.dtstart_property = nil
          @todo.finish_time.should be_nil
        end
      end

      context "and no duration" do
        it "should be nil" do
          @todo.finish_time.should be_nil
        end
      end
    end
  end

  describe "with both due and duration specified" do
    before(:each) do
      @it = RiCal::Component::Todo.parse_string("BEGIN:VTODO\nDUE:19970903T190000Z\nDURATION:H1\nEND:VTODO").first
    end
    
    it "should be invalid" do
      @it.should_not be_valid
    end
  end

  describe "with a duration property" do
    before(:each) do
      @it = RiCal::Component::Todo.parse_string("BEGIN:VTODO\nDURATION:H1\nEND:VTODO").first
    end

    it "should have a duration property" do
      @it.duration_property.should be
    end
    
    it "should have a duration of 1 Hour" do
      @it.duration_property.value.should == "H1"
    end
    
    it "should reset the duration property if the due property is set" do
      @it.due_property = "19970101T012345".to_ri_cal_date_time_value
      @it.duration_property.should be_nil
    end
    
    it "should reset the duration property if the dtend ruby value is set" do
      @it.due = "19970101"
      @it.duration_property.should == nil
    end
  end

  describe "with a due property" do
    before(:each) do
      @it = RiCal::Component::Todo.parse_string("BEGIN:VTODO\nDUE:19970903T190000Z\nEND:VTODO").first
    end

    it "should have a due property" do
      @it.due_property.should be
    end
    
    it "should reset the due property if the duration property is set" do
      @it.duration_property = "PT1H".to_ri_cal_duration_value
      @it.due_property.should be_nil
    end
    
    it "should reset the duration property if the dtend ruby value is set" do
      @it.duration = "PT1H"
      @it.due_property.should == nil
    end
  end
end