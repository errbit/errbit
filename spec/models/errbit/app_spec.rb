# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::App, type: :model do
  it "generates an API key and notice fingerprinter on create" do
    app = create(:errbit_app)

    expect(app.api_key).to be_present
    expect(app.notice_fingerprinter).to be_present
  end

  it "normalizes GitHub repository URLs" do
    app = create(:errbit_app, github_repo: "https://github.com/errbit/errbit.git")

    expect(app.github_repo).to eq("errbit/errbit")
  end

  it "copies editable app settings and relations from another app" do
    source = create(:errbit_app, github_repo: "errbit/errbit")
    create(:errbit_watcher, app: source, email: "alerts@example.com")
    create(:errbit_issue_tracker, app: source, type_tracker: "none", options: {"key" => "value"})
    create(:errbit_webhook_service, app: source, api_token: "https://example.com/hook")

    copy = build(:errbit_app, name: "Copy")
    copy.copy_attributes_from(source.id)

    expect(copy.github_repo).to eq("errbit/errbit")
    expect(copy.watchers.map(&:email)).to eq(["alerts@example.com"])
    expect(copy.issue_tracker.type_tracker).to eq("none")
    expect(copy.notification_service).to be_a(Errbit::NotificationServices::WebhookService)
  end
end
