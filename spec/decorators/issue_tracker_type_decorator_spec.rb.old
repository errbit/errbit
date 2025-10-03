# frozen_string_literal: true

require "rails_helper"

RSpec.describe IssueTrackerDecorator, type: :decorator do
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

  let(:fake_tracker) { IssueTrackerDecorator.new(fake_tracker_class.new) }
  let(:decorator) { IssueTrackerTypeDecorator.new(fake_tracker_class) }

  describe "::note" do
    it "return the html_safe of Note" do
      expect(decorator.note).to eql fake_tracker_class.note
    end
  end

  describe "#fields" do
    it "return all FIELDS define decorate" do
      decorator.fields do |itf|
        expect(itf).to be_a(IssueTrackerFieldDecorator)
        expect([:foo, :bar]).to be_include(itf.object)
        expect([{label: "foo"}, {label: "bar"}]).to be_include(itf.field_info)
      end
    end
  end

  describe "#params_class" do
    it "adds the label in class" do
      tracker = IssueTrackerDecorator.new(
        IssueTracker.new(type_tracker: "none")
      )
      expect(decorator.params_class(tracker)).to eql "fake"
    end

    it "adds chosen class if type is same" do
      expect(
        decorator
          .params_class(
            IssueTracker.new(
              type_tracker: "fake"
            ).decorate
          )
      ).to eql "chosen fake"
    end
  end
end
