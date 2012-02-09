#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[spec_helper])

describe RiCal do
  

  describe "#parse" do
    
    before(:each) do
      @mock_parser = mock("parser", :parse => [])
      RiCal::Parser.stub!(:new).and_return(@mock_parser)
    end
    
    it "should create a parser using the io parameter" do
      io = StringIO.new("")
      RiCal::Parser.should_receive(:new).with(io).and_return(@mock_parser)
      RiCal.parse(io)
    end
    
    it "should delegate to the parser" do
      io = StringIO.new("")
      @mock_parser.should_receive(:parse)
      RiCal.parse(io)
    end
    
    it "should return the results of the parse" do
      io = StringIO.new("")
      @mock_parser.stub!(:parse).and_return(:parse_result)
      RiCal.parse(io).should == :parse_result
    end
  end
  
  describe "#parse_string" do
    before(:each) do
      @mock_io = :mock_io
      StringIO.stub!(:new).and_return(@mock_io)
      RiCal.stub!(:parse)
    end
    
    it "should create a StringIO from the string" do
      string = "test string"
      StringIO.should_receive(:new).with(string)
      RiCal.parse_string(string)
    end
    
    it "should parse" do
      RiCal.should_receive(:parse).with(@mock_io)
      RiCal.parse_string("")
    end
  end

end