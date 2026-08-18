# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SQL HTML runtime", type: :request do
  let(:user) { create(:errbit_user, admin: true) }

  before do
    sign_in user
  end

  it "renders the apps index and show pages" do
    app = create(:errbit_app, name: "SQL App")

    get apps_path
    expect(response).to be_successful

    get new_app_path
    expect(response).to be_successful

    get app_path(app)
    expect(response).to be_successful

    get edit_app_path(app)
    expect(response).to be_successful
  end

  it "renders problem index and show pages" do
    app = create(:errbit_app)
    problem = create(:errbit_problem, app: app)
    err = create(:errbit_err, problem: problem)
    create(:errbit_notice, app: app, err: err)

    get app_problems_path(app)
    expect(response).to be_successful

    get app_problem_path(app, problem)
    expect(response).to be_successful
  end

  it "redirects notice lookup routes to SQL problem pages" do
    app = create(:errbit_app)
    problem = create(:errbit_problem, app: app)
    err = create(:errbit_err, problem: problem)
    notice = create(:errbit_notice, app: app, err: err)

    get locate_path(notice)
    expect(response).to redirect_to(app_problem_path(app, problem))

    get show_notice_by_id_path(notice)
    expect(response).to redirect_to(app_problem_path(app, problem, notice_id: notice.id))
  end

  it "creates, updates, copies, and deletes apps with nested SQL associations" do
    watcher = create(:errbit_user, email: "watcher@example.com", name: "Watcher User")

    post apps_path, params: {
      app: {
        name: "Created SQL App",
        email_at_notices: "1, 5",
        use_site_fingerprinter: "0",
        watchers_attributes: {
          "0" => {watcher_type: "user", errbit_user_id: watcher.id},
          "1" => {watcher_type: "email", email: "external@example.com"}
        },
        issue_tracker_attributes: {type_tracker: "none"},
        notification_service_attributes: {
          type: "Errbit::NotificationServices::SlackService",
          service_url: "https://hooks.slack.com/services/T/B/C",
          room_id: "#errors",
          notify_at_notices: "1, 2"
        },
        notice_fingerprinter_attributes: {message: "0", backtrace_lines: "3"}
      }
    }

    app = Errbit::App.find_by!(name: "Created SQL App")
    expect(response).to redirect_to(app_path(app))
    expect(app.attributes["email_at_notices"]).to eq([1, 5])
    expect(app.watchers.map(&:address)).to contain_exactly("watcher@example.com", "external@example.com")
    expect(app.issue_tracker.type_tracker).to eq("none")
    expect(app.notification_service).to be_a(Errbit::NotificationServices::SlackService)
    expect(app.notification_service.attributes["notify_at_notices"]).to eq([1, 2])
    expect(app.notice_fingerprinter.source).to eq(Errbit::SiteConfig::CONFIG_SOURCE_APP)

    patch app_path(app), params: {
      app: {
        name: "Updated SQL App",
        email_at_notices: "2, 3",
        use_site_fingerprinter: "1",
        notification_service_attributes: {
          type: "Errbit::NotificationServices::SlackService",
          service_url: "https://hooks.slack.com/services/T/B/C",
          room_id: "#alerts",
          notify_at_notices: "4"
        }
      }
    }

    expect(response).to redirect_to(app_path(app))
    expect(app.reload.name).to eq("Updated SQL App")
    expect(app.attributes["email_at_notices"]).to eq([2, 3])
    expect(app.notification_service.room_id).to eq("#alerts")
    expect(app.notice_fingerprinter.source).to eq(Errbit::SiteConfig::CONFIG_SOURCE_SITE)

    get new_app_path(copy_attributes_from: app.id)
    expect(response).to be_successful

    expect { delete app_path(app) }.to change(Errbit::App, :count).by(-1)
    expect(response).to redirect_to(apps_path)
  end

  it "filters, resolves, merges, and queues deletion for SQL problems" do
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear

    app = create(:errbit_app, name: "Problem App")
    visible = create(:errbit_problem, app: app, error_class: "VisibleError", environment: "production", message: "visible boom")
    hidden = create(:errbit_problem, app: app, error_class: "HiddenError", environment: "staging", message: "hidden boom")
    first_err = create(:errbit_err, problem: visible, fingerprint: "visible")
    second_err = create(:errbit_err, problem: hidden, fingerprint: "hidden")
    create(:errbit_notice, app: app, err: first_err, message: "visible notice")
    create(:errbit_notice, app: app, err: second_err, message: "hidden notice")

    get problems_path(search: "VisibleError", environment: "production", sort: "message", order: "asc")
    expect(response).to be_successful
    expect(response.body).to include("VisibleError")
    expect(response.body).not_to include("HiddenError")

    patch resolve_app_problem_path(app, visible)
    expect(response).to redirect_to(root_path)
    expect(visible.reload).to be_resolved

    post merge_several_problems_path, params: {problems: [visible.id, hidden.id]}
    expect(response).to redirect_to(root_path)
    expect(Errbit::Problem.exists?(hidden.id)).to eq(false)
    expect(visible.reload.errs.pluck(:fingerprint)).to contain_exactly("visible", "hidden")

    post destroy_several_problems_path, params: {problems: [visible.id]}
    expect(response).to redirect_to(root_path)
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.map { |job| job[:job] }).to include(Errbit::DestroyProblemsByIdJob)
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter if previous_adapter
  end
end
