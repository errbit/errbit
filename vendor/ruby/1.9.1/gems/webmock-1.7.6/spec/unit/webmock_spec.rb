require 'spec_helper'

describe "WebMock version" do
  it "should report version" do
    WebMock.version.should == WebMock::VERSION
  end
end