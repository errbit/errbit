require 'spec_helper'

describe BacktraceLineNormalizer do
  subject { described_class.new(raw_line).call }

  describe "sanitize file and method" do
    let(:raw_line) { { 'number' => rand(999), 'file' => nil, 'method' => nil } }

    it "should replace nil file with [unknown source]" do
      subject['file'].should == "[unknown source]"
    end

    it "should replace nil method with [unknown method]" do
      subject['method'].should == "[unknown method]"
    end

  end
end
