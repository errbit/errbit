require 'spec_helper'

describe BacktraceLineNormalizer do
  subject { described_class.new(raw_line).call }

  describe "sanitize" do
    context "unknown file and method" do
      let(:raw_line) { { 'number' => rand(999), 'file' => nil, 'method' => nil } }

      it "should replace nil file with [unknown source]" do
        expect(subject['file']).to eq "[unknown source]"
      end

      it "should replace nil method with [unknown method]" do
        expect(subject['method']).to eq "[unknown method]"
      end
    end

    context "in app file" do
      let(:raw_line) { { 'number' => rand(999), 'file' => "[PROJECT_ROOT]/assets/file.js?body=1", 'method' => nil } }

      it "should strip query strings from files" do
        expect(subject['file']).to eq "[PROJECT_ROOT]/assets/file.js"
      end
    end
  end
end
