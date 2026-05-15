# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::IssueTrackerTypeDecorator, type: :decorator do
  let(:fake_tracker_class) do
    klass = Class.new(ErrbitPlugin::IssueTracker) do
      def self.label
        "fake"
      end

      def self.note
        "a note"
      end

      def self.fields
        {
          foo: {label: "foo"},
          bar: {label: "bar"}
        }
      end

      def self.icons
        {
          one: ["text/plain", "all your base are belong to us"],
          two: ["application/xml", "<root></root>"]
        }
      end
    end

    allow(ErrbitPlugin::Registry).to receive(:issue_trackers).and_return(fake: klass)

    klass
  end

  let(:decorator) { described_class.new(fake_tracker_class) }

  describe ".note" do
    it "returns html_safe note" do
      expect(decorator.note).to eq(fake_tracker_class.note)
    end
  end

  describe "#fields" do
    it "yields a decorated field for each entry" do
      decorator.fields do |itf|
        expect(itf).to be_a(Errbit::IssueTrackerFieldDecorator)
        expect([:foo, :bar]).to be_include(itf.object)
        expect([{label: "foo"}, {label: "bar"}]).to be_include(itf.field_info)
      end
    end
  end

  describe "#params_class" do
    it "includes the label" do
      tracker = Errbit::IssueTrackerDecorator.new(
        Errbit::IssueTracker.new(type_tracker: "none")
      )

      expect(decorator.params_class(tracker)).to eq("fake")
    end

    it "prepends 'chosen' when the tracker type matches" do
      tracker = Errbit::IssueTrackerDecorator.new(
        Errbit::IssueTracker.new(type_tracker: "fake")
      )

      expect(decorator.params_class(tracker)).to eq("chosen fake")
    end
  end

  describe "#icons" do
    it "returns data URIs for each icon" do
      result = decorator.icons

      expect(result.keys).to match_array([:one, :two])
      expect(result[:one]).to start_with("data:text/plain;base64,")
      expect(result[:two]).to start_with("data:application/xml;base64,")
    end
  end
end
