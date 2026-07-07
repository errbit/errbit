# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::IssueTrackerFieldDecorator, type: :decorator do
  describe "#label" do
    it "returns the label from field_info when present" do
      expect(described_class.new(:foo, label: "hello").label).to eq("hello")
    end

    it "falls back to the titleized key when no label is provided" do
      expect(described_class.new(:foo, {}).label).to eq("Foo")
    end
  end
end
