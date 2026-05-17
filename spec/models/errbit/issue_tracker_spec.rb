# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::IssueTracker, type: :model do
  it "inherits from Errbit::ApplicationRecord" do
    expect(described_class.ancestors).to include(Errbit::ApplicationRecord)
  end

  it "uses the errbit_issue_trackers table" do
    expect(described_class.table_name).to eq("errbit_issue_trackers")
  end

  describe "associations" do
    it "can belong to an app" do
      app = create(:errbit_app)
      tracker = create(:errbit_issue_tracker, app: app)

      expect(tracker.app).to eq(app)
      expect(app.reload.issue_tracker).to eq(tracker)
    end

    it "is destroyed when its app is destroyed" do
      tracker = create(:errbit_issue_tracker)

      expect {
        tracker.app.destroy
      }.to change(described_class, :count).by(-1)
    end
  end

  describe "#type_tracker" do
    it "returns the stored value when set" do
      tracker = described_class.new(type_tracker: "github")

      expect(tracker.type_tracker).to eq("github")
    end

    it "defaults to 'none' when not set" do
      tracker = described_class.new

      expect(tracker.type_tracker).to eq("none")
    end
  end

  describe "#options" do
    it "defaults to an empty hash" do
      expect(described_class.new.options).to eq({})
    end

    it "stores arbitrary key/values" do
      tracker = create(:errbit_issue_tracker, options: {"a" => "1", "b" => "2"})

      expect(tracker.reload.options).to eq("a" => "1", "b" => "2")
    end
  end

  describe "#tracker" do
    context "with an unknown type_tracker" do
      let(:app) { create(:errbit_app) }

      it "returns ErrbitPlugin::NoneIssueTracker" do
        issue_tracker = described_class.new(type_tracker: "Foo", app: app)

        expect(issue_tracker.tracker).to be_a(ErrbitPlugin::NoneIssueTracker)
      end
    end

    it "passes github_repo and bitbucket_repo from the app into the tracker options" do
      app = create(:errbit_app, github_repo: "owner/gh", bitbucket_repo: "owner/bb")
      tracker = described_class.new(type_tracker: "Foo", app: app, options: {"extra" => "value"})

      none_tracker = tracker.tracker

      expect(none_tracker).to be_a(ErrbitPlugin::NoneIssueTracker)
    end

    it "memoizes the tracker instance" do
      tracker = described_class.new(type_tracker: "Foo")

      expect(tracker.tracker).to equal(tracker.tracker)
    end
  end
end
