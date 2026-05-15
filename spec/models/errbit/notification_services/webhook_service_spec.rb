# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::NotificationServices::WebhookService, type: :model do
  let(:service) { build(:errbit_webhook_notification_service, api_token: "https://example.com/hook") }
  let(:problem) { create(:errbit_problem) }

  describe "validations" do
    it "requires api_token" do
      service.api_token = ""
      service.valid?

      expect(service.errors[:base]).to include("You must specify the URL")
    end

    it "is valid with api_token" do
      service.api_token = "https://example.com/hook"

      expect(service.valid?).to eq(true)
    end
  end

  describe "#message_for_webhook" do
    it "wraps problem JSON under a :problem key with the url merged in" do
      payload = service.message_for_webhook(problem)

      expect(payload[:problem]).to be_a(Hash)
      expect(payload[:problem][:url]).to eq(problem.url)
    end
  end

  describe "#create_notification" do
    it "POSTs the payload to api_token" do
      payload = service.message_for_webhook(problem)

      expect(HTTParty).to receive(:post)
        .with(
          service.api_token,
          headers: {"Content-Type" => "application/json", "User-Agent" => "Errbit"},
          body: payload.to_json
        )
        .and_return(true)

      service.create_notification(problem)
    end
  end
end
