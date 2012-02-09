#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe RiCal::Component::Alarm do
  
  describe ".entity_name" do
    it "should be VALARM" do
      RiCal::Component::Alarm.entity_name.should == "VALARM"
    end
  end
end
