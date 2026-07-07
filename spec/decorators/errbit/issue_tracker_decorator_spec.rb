# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::IssueTrackerDecorator, type: :decorator do
  let(:fake_tracker) do
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

      def configured?
        true
      end
    end
    klass.new "nothing special"
  end

  let(:issue_tracker) do
    it = Errbit::IssueTracker.new
    allow(it).to receive(:tracker).and_return(fake_tracker)
    it
  end

  let(:decorator) { described_class.new(issue_tracker) }

  describe "#type" do
    it "returns Errbit::IssueTrackerTypeDecorator for the tracker class" do
      expect(decorator.type.class).to eq(Errbit::IssueTrackerTypeDecorator)
    end
  end
end
