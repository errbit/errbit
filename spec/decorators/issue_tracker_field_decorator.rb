# frozen_string_literal: true

require "rails_helper"

# TODO: rename this file to _spec.rb
RSpec.describe IssueTrackerFieldDecorator, type: :decorator do
  describe "#label" do
    it "return the label of field_info by default" do
      expect(IssueTrackerFieldDecorator.new(:foo, label: "hello").label).to eq "hello"
    end

    it "return the key of field if no label define" do
      expect(IssueTrackerFieldDecorator.new(:foo, {}).label).to eq "foo"
    end
  end
end
