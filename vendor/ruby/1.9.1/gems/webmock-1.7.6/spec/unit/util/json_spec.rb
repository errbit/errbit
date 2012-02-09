require 'spec_helper'

describe WebMock::Util::JSON do
  it "should parse json without parsing dates" do
    WebMock::Util::JSON.parse("\"a\":\"2011-01-01\"").should == {"a" => "2011-01-01"}
  end
end