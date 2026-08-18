# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Mailer, type: :mailer do
  let(:app) { create(:errbit_app, name: "Mailer App", notify_on_errs: true) }
  let(:user) { create(:errbit_user, name: "Commenter", email: "commenter@example.com") }
  let!(:watcher) { create(:errbit_watcher, app: app, email: "watcher@example.com") }
  let(:problem) { create(:errbit_problem, app: app, notices_count: 1, environment: "production") }
  let(:err) { create(:errbit_err, problem: problem) }
  let(:notice) { create(:errbit_notice, app: app, err: err, message: "RuntimeError: mailer boom") }

  describe "#err_notification" do
    it "renders the SQL error notification" do
      error_report = Struct.new(:notice, :app, :problem).new(notice, app, problem)
      mail = described_class.with(error_report: error_report).err_notification

      expect(mail.to).to eq(["watcher@example.com"])
      expect(mail.subject).to include("[Mailer App][production] RuntimeError: mailer boom")
      expect(mail["X-Errbit-App"].to_s).to eq("Mailer App")
    end
  end

  describe "#comment_notification" do
    it "renders the SQL comment notification" do
      notice
      comment = build(:errbit_comment, err: problem, user: user, body: "Please check this")
      mail = described_class.with(comment: comment).comment_notification

      expect(mail.to).to eq(["watcher@example.com"])
      expect(mail.subject).to include("Commenter commented on [Mailer App][production]")
      expect(mail.body.encoded).to include("Please check this")
    end
  end
end
