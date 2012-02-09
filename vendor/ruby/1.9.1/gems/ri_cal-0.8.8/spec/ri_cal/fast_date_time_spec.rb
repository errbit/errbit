#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. spec_helper])

module RiCal

  describe RiCal::FastDateTime do
    context "#utc" do
      it "should not change if it is already UTC" do
        FastDateTime.new(2009, 5, 29, 19, 3, 0, 0).utc.should == FastDateTime.new(2009, 5, 29, 19, 3, 0, 0)        
      end
      
      it "should change the time by the offset" do
        FastDateTime.new(2010, 4, 15, 16, 3, 0, -4*60*60).utc.should == FastDateTime.new(2010, 4, 15, 20, 3, 0, 0)
      end
    end
    
    context "#==" do
      it "should detect equal FastDateTimes" do
        FastDateTime.new(2009, 5, 29, 19, 3, 0, 0).should == 
        FastDateTime.new(2009, 5, 29, 19, 3, 0, 0)
      end

      it "should detect unequal FastDateTimes" do
        FastDateTime.new(2009, 5, 29, 19, 3, 0, 0).should_not == 
        FastDateTime.new(2009, 5, 29, 19, 3, 10, 0)      
      end

      context "#advance" do
        it "should advance one second" do
          FastDateTime.new(2009, 5, 29, 19, 3, 0, 0).advance(:seconds => 1).should == 
          FastDateTime.new(2009, 5, 29, 19, 3, 1, 0)
        end

        it "should advance minus one second" do
          FastDateTime.new(2009, 5, 29, 19, 3, 0, 0).advance(:seconds => -1).should == 
          FastDateTime.new(2009, 5, 29, 19, 2, 59, 0)
        end

        it "should advance 70 seconds" do
          FastDateTime.new(2009, 5, 29, 19, 3, 0, 0).advance(:seconds => 70).should == 
          FastDateTime.new(2009, 5, 29, 19, 4, 10, 0)
        end

        it "should advance -70 seconds" do
          FastDateTime.new(2009, 5, 29, 19, 3, 0, 0).advance(:seconds => -70).should == 
          FastDateTime.new(2009, 5, 29, 19, 1, 50, 0)
        end
        
        it "should advance one minute" do
          FastDateTime.new(2009, 5, 29, 19, 3, 0, 0).advance(:minutes => 1).should == 
          FastDateTime.new(2009, 5, 29, 19, 4, 0, 0)
        end

        it "should advance minus one minute" do
          FastDateTime.new(2009, 5, 29, 19, 3, 0, 0).advance(:minutes => -1).should == 
          FastDateTime.new(2009, 5, 29, 19, 2, 0, 0)
        end

        it "should advance 70 minutes" do
          FastDateTime.new(2009, 5, 29, 19,  3, 0, 0).advance(:minutes => 70).should == 
          FastDateTime.new(2009, 5, 29, 20, 13, 0, 0)
        end

        it "should advance -70 minutes" do
          FastDateTime.new(2009, 5, 29, 19,  3, 0, 0).advance(:minutes => -70).should == 
          FastDateTime.new(2009, 5, 29, 17, 53, 0, 0)
        end
        
        it "should advance properly over a date" do
          FastDateTime.new(2009, 5, 29, 23,  3, 0, 0).advance(:minutes => 70).should == 
          FastDateTime.new(2009, 5, 30,  0, 13, 0, 0)          
        end
      end
    end
  end
end
