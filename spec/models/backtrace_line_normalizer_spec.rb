require 'spec_helper'

describe BacktraceLineNormalizer do
  subject { described_class.new(raw_line).call }

  describe "sanitize file" do
    let(:raw_line) { { 'number' => rand(999), 'file' => nil, 'method' => ActiveSupport.methods.shuffle.first.to_s } }

    it "should replace nil file with [unknown source]" do
      subject['file'].should == "[unknown source]"
    end

  end
end
