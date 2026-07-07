# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::NotificationServices::SlackService, type: :model do
  let(:backtrace) do
    create(:errbit_backtrace,
      lines: [
        {"number" => 22, "file" => "/path/to/file/1.rb", "method" => "first_method"},
        {"number" => 44, "file" => "/path/to/file/2.rb", "method" => "second_method"},
        {"number" => 11, "file" => "/path/to/file/3.rb", "method" => "third_method"},
        {"number" => 103, "file" => "/path/to/file/4.rb", "method" => "fourth_method"},
        {"number" => 923, "file" => "/path/to/file/5.rb", "method" => "fifth_method"},
        {"number" => 8, "file" => "/path/to/file/6.rb", "method" => "sixth_method"}
      ])
  end

  let(:notice) { create(:errbit_notice, backtrace: backtrace) }
  let(:problem) { notice.err.problem }
  let(:service_url) { "https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXX" }
  let(:room_id) { "#general" }
  let(:service) do
    create(:errbit_slack_notification_service,
      app: notice.app,
      service_url: service_url,
      room_id: room_id)
  end

  context "validations" do
    it "requires service_url" do
      service.service_url = ""
      service.valid?

      expect(service.errors[:service_url])
        .to include("You must specify your Slack Hook url")

      service.service_url = service_url
      service.valid?

      expect(service.errors[:service_url]).to be_blank
    end

    it "validates the format of room_id" do
      service.room_id = "INVALID NAME"
      service.valid?

      expect(service.errors[:room_id])
        .to include("Slack channel name must be lowercase, with no space, special character, or periods.")

      service.room_id = "#valid-room-name"
      service.valid?

      expect(service.errors[:room_id]).to be_blank
    end

    it "allows blank room_id" do
      service.room_id = nil

      expect(service.valid?).to eq(true)
    end
  end

  describe "#configured?" do
    it "is true when service_url is present" do
      expect(service.configured?).to eq(true)
    end

    it "is false when service_url is blank" do
      service.service_url = nil

      expect(service.configured?).to eq(false)
    end
  end

  describe "#message_for_slack" do
    it "formats a single-line summary including url" do
      expect(service.message_for_slack(problem))
        .to include(problem.app.name, problem.environment, problem.error_class.to_s)
    end
  end

  describe "#create_notification" do
    context "with room_id" do
      it "POSTs the payload to the Slack webhook" do
        expect(HTTParty).to receive(:post)
          .with(service.service_url,
            body: service.post_payload(problem),
            headers: {"Content-Type" => "application/json"})
          .and_return(true)

        service.create_notification(problem)
      end

      it "includes the channel in the payload" do
        payload = JSON.parse(service.post_payload(problem))

        expect(payload["channel"]).to eq(room_id)
      end
    end

    context "without room_id" do
      let(:room_id) { nil }

      it "omits channel from the payload" do
        payload = JSON.parse(service.post_payload(problem))

        expect(payload).not_to have_key("channel")
      end
    end
  end

  it "has the icon asset present in the repo" do
    expect(Rails.root.join("docs/notifications/slack/errbit.png")).to exist
  end
end
