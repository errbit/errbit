# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::NotificationService, type: :model do
  it "inherits from Errbit::ApplicationRecord" do
    expect(described_class.ancestors).to include(Errbit::ApplicationRecord)
  end

  it "uses the errbit_notification_services table" do
    expect(described_class.table_name).to eq("errbit_notification_services")
  end

  describe "single-table inheritance" do
    it "persists subclass via the type column" do
      service = create(:errbit_webhook_notification_service, api_token: "https://example.com/hook")

      expect(service[:type]).to eq("Errbit::NotificationServices::WebhookService")
      expect(described_class.find(service.id)).to be_a(Errbit::NotificationServices::WebhookService)
    end
  end

  describe ".label" do
    it "returns the LABEL constant on the class" do
      expect(Errbit::NotificationServices::WebhookService.label).to eq("webhook")
      expect(Errbit::NotificationServices::SlackService.label).to eq("slack")
    end
  end

  describe "#label" do
    it "returns the class label" do
      service = Errbit::NotificationServices::SlackService.new

      expect(service.label).to eq("slack")
    end
  end

  describe "#configured?" do
    it "is true when api_token is present" do
      service = described_class.new(api_token: "abc")

      expect(service.configured?).to eq(true)
    end

    it "is false when api_token is blank" do
      service = described_class.new

      expect(service.configured?).to eq(false)
    end
  end

  describe "#notification_description" do
    it "formats environment, where, and a truncated message" do
      problem = build(:errbit_problem,
        environment: "production",
        message: "x" * 200)

      allow(problem).to receive(:where).and_return("widgets#show")

      service = described_class.new
      description = service.notification_description(problem)

      expect(description).to start_with("[production][widgets#show]")
      expect(description).to include("...")
    end
  end

  describe "#notify_at_notices" do
    context "when per_app_notify_at_notices is false" do
      before { allow(Errbit::Config).to receive(:per_app_notify_at_notices).and_return(false) }

      it "always returns the global config" do
        allow(Errbit::Config).to receive(:notify_at_notices).and_return([10])
        service = described_class.new(notify_at_notices: [1, 2, 3])

        expect(service.notify_at_notices).to eq([10])
      end
    end

    context "when per_app_notify_at_notices is true" do
      before { allow(Errbit::Config).to receive(:per_app_notify_at_notices).and_return(true) }

      it "returns the stored value when present" do
        service = described_class.new(notify_at_notices: [1, 5])

        expect(service.notify_at_notices).to eq([1, 5])
      end

      it "falls back to the global config when nothing is stored" do
        allow(Errbit::Config).to receive(:notify_at_notices).and_return([0])
        service = described_class.new

        expect(service.notify_at_notices).to eq([0])
      end
    end
  end

  describe "association" do
    it "can belong to an app" do
      app = create(:errbit_app)
      service = create(:errbit_webhook_notification_service, app: app, api_token: "https://example.com/h")

      expect(service.app).to eq(app)
      expect(app.reload.notification_service).to eq(service)
    end

    it "is destroyed when its app is destroyed" do
      service = create(:errbit_webhook_notification_service, api_token: "https://example.com/h")

      expect {
        service.app.destroy
      }.to change(described_class, :count).by(-1)
    end
  end
end
