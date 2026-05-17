# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "an Errbit notification email" do
  it "has the X-Mailer header" do
    expect(email).to have_header("X-Mailer", "Errbit")
  end

  it "has the X-Errbit-Host header" do
    expect(email).to have_header("X-Errbit-Host", Errbit::Config.host)
  end

  it "has the Precedence header" do
    expect(email).to have_header("Precedence", "bulk")
  end

  it "has the Auto-Submitted header" do
    expect(email).to have_header("Auto-Submitted", "auto-generated")
  end

  it "has the X-Auto-Response-Suppress header" do
    expect(email).to have_header("X-Auto-Response-Suppress", "OOF, AutoReply")
  end

  it "delivers the email" do
    email

    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end
end

RSpec.describe Errbit::Mailer do
  context "with an Err notification" do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    let(:notice) do
      n = create(:errbit_notice, message: "class < ActionController::Base")
      # Use a JS file so the email's per-file link shows the asset-host URL
      n.backtrace.lines[-1] = n.backtrace.lines.last.merge("file" => "[PROJECT_ROOT]/path/to/file.js")
      n
    end

    let(:app) do
      a = notice.app
      a.update!(asset_host: "http://example.com", notify_all_users: true)
      a
    end

    let(:problem) do
      p = notice.err.problem
      p.notices_count = 3
      p
    end

    let!(:user) { create(:errbit_user, admin: true) }

    let(:error_report) do
      instance_double(
        "Errbit::ErrorReport",
        notice: notice,
        app: app,
        problem: problem
      )
    end

    let(:email) do
      Errbit::Mailer.with(error_report: error_report).err_notification.deliver_now
    end

    before { email }

    it_behaves_like "an Errbit notification email"

    it "html-escapes the notice's message in the html part" do
      html_body = email.body.parts.detect { |p| p.content_type.match(/html/) }.body.raw_source

      expect(html_body).to match("class &lt; ActionController::Base")
    end

    it "inlines styles in the backtrace markup" do
      expect(email).to have_body_text('<p class="backtrace" style="')
    end

    it "links to the source file via the app's asset host" do
      expect(email).to have_body_text('<a target="_blank" rel="noopener noreferrer" href="http://example.com/path/to/file.js"> path/to/file.js')
    end

    it "puts the error count in the subject" do
      expect(email.subject).to match(/^\(3\) /)
    end

    context "with a very long message" do
      let(:notice) { create(:errbit_notice, message: 6.times.collect { |_a| "0123456789" }.join("")) }

      it "truncates the long message" do
        expect(email.subject).to match(/ \d{47}\.{3}$/)
      end
    end
  end

  context "with a Comment notification" do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    let!(:err) { create(:errbit_err) }
    let!(:notice) { create(:errbit_notice, err: err, app: err.app) }
    let!(:comment) { create(:errbit_comment, err: notice.err.problem) }
    let!(:watcher) { create(:errbit_watcher, app: comment.app) }

    let(:recipients) { ["recipient@example.com", "another@example.com"] }

    before do
      expect(comment).to receive(:notification_recipients).and_return(recipients)
      create(:errbit_notice, err: notice.err, app: notice.err.app)
      # The Errbit::Notice factory doesn't call Errbit::Problem.cache_notice
      # (the Mongoid notice factory did). Bump the cached count to match the
      # "2 notices were created" expectation in the body assertion below.
      notice.err.problem.update!(notices_count: 2)
      @email = Errbit::Mailer.with(comment: comment).comment_notification.deliver_now
    end

    it "is sent to the comment's notification recipients" do
      expect(@email.to).to eq(recipients)
    end

    it "includes the notices count in the body" do
      expect(@email).to have_body_text("This error has occurred 2 times")
    end

    it "includes the comment body" do
      expect(@email).to have_body_text(comment.body)
    end
  end
end
