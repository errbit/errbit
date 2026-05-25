# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#tally" do
    it "converts a digest-keyed collection into a {value => count} hash" do
      collection = {
        "d1" => {"value" => "foo", "count" => 3},
        "d2" => {"value" => "bar", "count" => 7}
      }

      expect(helper.tally(collection)).to eq("foo" => 3, "bar" => 7)
    end

    it "returns an empty hash when the collection is empty" do
      expect(helper.tally({})).to eq({})
    end

    it "collapses duplicate values onto the last count seen" do
      collection = {
        "d1" => {"value" => "foo", "count" => 3},
        "d2" => {"value" => "foo", "count" => 5}
      }

      expect(helper.tally(collection)).to eq("foo" => 5)
    end
  end

  describe "#head" do
    it "returns the first 4 elements" do
      expect(helper.head((1..10).to_a)).to eq([1, 2, 3, 4])
    end

    it "returns the whole collection when it is smaller than the head size" do
      expect(helper.head([1, 2])).to eq([1, 2])
    end

    it "returns an empty array when the collection is empty" do
      expect(helper.head([])).to eq([])
    end
  end

  describe "#tail" do
    it "returns elements after the first 4" do
      expect(helper.tail((1..10).to_a)).to eq([5, 6, 7, 8, 9, 10])
    end

    it "returns an empty array when the collection is smaller than the head size" do
      expect(helper.tail([1, 2])).to eq([])
    end

    it "returns an empty array when the collection is empty" do
      expect(helper.tail([])).to eq([])
    end
  end

  describe "#create_percentage_table_from_tallies" do
    it "renders the partial with rows sorted by descending percentage" do
      result = helper.create_percentage_table_from_tallies("foo" => 1, "bar" => 3)

      expect(result).to include("75.0%")
      expect(result).to include("25.0%")
      expect(result.index("bar")).to be < result.index("foo")
    end

    it "uses the supplied total when provided" do
      result = helper.create_percentage_table_from_tallies({"foo" => 1}, total: 4)

      expect(result).to include("25.0%")
    end

    it "renders the show-more footer when there are more rows than the head size" do
      tallies = {"a" => 1, "b" => 1, "c" => 1, "d" => 1, "e" => 1}

      expect(helper.create_percentage_table_from_tallies(tallies)).to include("Show more...")
    end

    it "omits the show-more footer when there are no rows beyond the head" do
      tallies = {"a" => 1, "b" => 1}

      expect(helper.create_percentage_table_from_tallies(tallies)).not_to include("Show more...")
    end
  end

  describe "#create_percentage_table_for" do
    it "tallies the collection and renders the partial" do
      collection = {
        "d1" => {"value" => "foo", "count" => 1},
        "d2" => {"value" => "bar", "count" => 3}
      }

      result = helper.create_percentage_table_for(collection)

      expect(result).to include("foo")
      expect(result).to include("bar")
      expect(result).to include("75.0%")
      expect(result).to include("25.0%")
    end
  end

  describe "#message_graph" do
    it "delegates to #create_percentage_table_for with the problem's messages" do
      problem = double(messages: {"d" => {"value" => "msg", "count" => 1}})

      expect(helper).to receive(:create_percentage_table_for).with(problem.messages).and_return("rendered")
      expect(helper.message_graph(problem)).to eq("rendered")
    end
  end

  describe "#user_agent_graph" do
    it "delegates to #create_percentage_table_for with the problem's user_agents" do
      problem = double(user_agents: {"d" => {"value" => "ua", "count" => 1}})

      expect(helper).to receive(:create_percentage_table_for).with(problem.user_agents).and_return("rendered")
      expect(helper.user_agent_graph(problem)).to eq("rendered")
    end
  end

  describe "#tenant_graph" do
    it "delegates to #create_percentage_table_for with the problem's hosts" do
      problem = double(hosts: {"d" => {"value" => "host", "count" => 1}})

      expect(helper).to receive(:create_percentage_table_for).with(problem.hosts).and_return("rendered")
      expect(helper.tenant_graph(problem)).to eq("rendered")
    end
  end

  describe "#issue_tracker_types" do
    let(:fake_tracker_class) do
      Class.new(ErrbitPlugin::IssueTracker) do
        def self.label
          "fake"
        end

        def self.note
          "a note"
        end

        def self.fields
          {}
        end

        def self.icons
          {}
        end
      end
    end

    it "wraps every registered tracker in an Errbit::IssueTrackerTypeDecorator" do
      allow(ErrbitPlugin::Registry).to receive(:issue_trackers).and_return(fake: fake_tracker_class)

      types = helper.issue_tracker_types

      expect(types.size).to eq(1)
      expect(types.first).to be_a(Errbit::IssueTrackerTypeDecorator)
      expect(types.first.object).to eq(fake_tracker_class)
    end

    it "returns an empty array when no trackers are registered" do
      allow(ErrbitPlugin::Registry).to receive(:issue_trackers).and_return({})

      expect(helper.issue_tracker_types).to eq([])
    end
  end

  describe "#generate_problem_ical" do
    let(:notice) { create(:errbit_notice) }

    it "renders the ical format without raising" do
      expect { helper.generate_problem_ical([notice]) }.not_to raise_error
    end

    it "returns a VCALENDAR document" do
      ical = helper.generate_problem_ical([notice])

      expect(ical).to include("BEGIN:VCALENDAR")
      expect(ical).to include("END:VCALENDAR")
    end

    it "emits one VEVENT per notice with summary indexed from 1" do
      other = create(:errbit_notice)
      ical = helper.generate_problem_ical([notice, other])

      expect(ical.scan("BEGIN:VEVENT").size).to eq(2)
      expect(ical).to match(/SUMMARY:1 #{Regexp.escape(notice.message)}/)
      expect(ical).to match(/SUMMARY:2 #{Regexp.escape(other.message)}/)
    end

    it "produces an empty calendar when there are no notices" do
      ical = helper.generate_problem_ical([])

      expect(ical).to include("BEGIN:VCALENDAR")
      expect(ical).not_to include("BEGIN:VEVENT")
    end

    it "includes the notice URL when one is present" do
      notice.request = notice.request.merge("url" => "https://example.com/boom")
      notice.save!

      expect(helper.generate_problem_ical([notice])).to include("https://example.com/boom")
    end
  end
end
