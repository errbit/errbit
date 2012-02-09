#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe RiCal::PropertyValue::UtcOffset do
  
  describe "with a positive sign and seconds" do
    before(:each) do
      @it = RiCal::PropertyValue::UtcOffset.new(nil, :value => "+013015")
    end
    
    it "should have +1 as its sign" do
      @it.sign.should == 1
    end
    
    it "should have 1 as its hours" do
      @it.hours.should == 1
    end
    
    it "should have 30 as its minutes" do
      @it.minutes.should == 30
    end
    
    it "should have 15 as its seconds" do
      @it.seconds.should == 15
    end    
  end
  
  describe "with seconds omitted" do
    before(:each) do
      @it = RiCal::PropertyValue::UtcOffset.new(nil, :value => "+0130")
    end
        
    it "should have 0 as its seconds" do
      @it.seconds.should == 0
    end    
  end
  describe "with a negative sign" do
    before(:each) do
      @it = RiCal::PropertyValue::UtcOffset.new(nil, :value => "-013015")
    end
    
    it "should have +1 as its sign" do
      @it.sign.should == -1
    end
    
  end
end