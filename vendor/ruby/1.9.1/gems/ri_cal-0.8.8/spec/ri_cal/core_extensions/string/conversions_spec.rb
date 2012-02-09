#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe RiCal::CoreExtensions::String::Conversions do
  context "#to_ri_cal_date_time_value" do
    
    it "should produce a DateTime property for a valid RFC 2445 datetime string" do
      "20090304T123456".to_ri_cal_date_time_value.should == RiCal::PropertyValue::DateTime.new(nil, :value => "20090304T123456")
    end
    
    it "should produce a DateTime property for a valid RFC 2445 datetime string with a TZID parameter" do
      "TZID=America/New_York:20090304T123456".to_ri_cal_date_time_value.should == RiCal::PropertyValue::DateTime.new(nil, :params => {"TZID" => "America/New_York"}, :value => "20090304T123456")
    end
    
    it "should raise an InvalidPropertyValue error if the string is not a valid RFC 2445 datetime string" do
      lambda {"20090304".to_ri_cal_date_time_value}.should raise_error(RiCal::InvalidPropertyValue)
    end
  end
  
  context "#to_ri_cal_duration_value" do
    
    it "should produce a Duration property for a valid RFC 2445 duration string" do
      "PT1H".to_ri_cal_duration_value.should == RiCal::PropertyValue::Duration.new(nil, :value => "PT1H")
    end
    
    it "should raise an InvalidPropertyValue error if the string is not a valid RFC 2445 datetime string" do
      lambda {"20090304".to_ri_cal_duration_value}.should raise_error(RiCal::InvalidPropertyValue)
    end
  end
  
  context "#to_ri_cal_date_or_date_time_value" do
    
    it "should produce a DateTime property for a valid RFC 2445 datetime string" do
      "20090304T123456".to_ri_cal_date_or_date_time_value.should == RiCal::PropertyValue::DateTime.new(nil, :value => "20090304T123456")
    end
    
    it "should produce a DateTime property for a valid RFC 2445 datetime string with a TZID parameter" do
      "TZID=America/New_York:20090304T123456".to_ri_cal_date_or_date_time_value.should == RiCal::PropertyValue::DateTime.new(nil, :params => {"TZID" => "America/New_York"}, :value => "20090304T123456")
    end

    it "should produce a Date property for a valid RFC 2445 date string" do
      "20090304".to_ri_cal_date_or_date_time_value.should == RiCal::PropertyValue::Date.new(nil, :value => "20090304")
    end
    
    
    it "should raise an InvalidPropertyValue error if the string is not a valid RFC 2445 date or datetime string" do
      lambda {"2009/03/04".to_ri_cal_date_or_date_time_value}.should raise_error(RiCal::InvalidPropertyValue)
    end
  end
  
  context "#to_ri_cal_occurrence_list_value" do
    
    it "should produce a DateTime property for a valid RFC 2445 datetime string" do
      "20090304T123456".to_ri_cal_occurrence_list_value.should == RiCal::PropertyValue::DateTime.new(nil, :value => "20090304T123456")
    end
    
    it "should produce a DateTime property for a valid RFC 2445 datetime string with a TZID parameter" do
      "TZID=America/New_York:20090304T123456".to_ri_cal_occurrence_list_value.should == RiCal::PropertyValue::DateTime.new(nil, :params => {"TZID" => "America/New_York"}, :value => "20090304T123456")
    end

    it "should produce a Date property for a valid RFC 2445 date string" do
      "20090304".to_ri_cal_occurrence_list_value.should == RiCal::PropertyValue::Date.new(nil, :value => "20090304")
    end
    
    it "should produce a Period property for a valid RFC 2445 period string (two time format)" do
      "20090304T012345/20090304T023456".to_ri_cal_occurrence_list_value.should == RiCal::PropertyValue::Period.new(nil, :value => "20090304T012345/20090304T023456")
    end

    it "should produce a Period property for a valid RFC 2445 period string (time and duration format)" do
      "20090304T012345/PT1H".to_ri_cal_occurrence_list_value.should == RiCal::PropertyValue::Period.new(nil, :value => "20090304T012345/PT1H")
    end

    it "should raise an InvalidPropertyValue error if the string is not a valid RFC 2445 date or datetime string" do
      lambda {"foobar".to_ri_cal_date_or_date_time_value}.should raise_error(RiCal::InvalidPropertyValue)
    end
  end
end
