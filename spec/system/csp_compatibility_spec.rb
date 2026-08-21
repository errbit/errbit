# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CSP-compatible browser behavior", type: :system, retry: 3 do
  let!(:user) { create(:errbit_user, admin: true) }

  it "loads the notice sparkline" do
    app = create(:errbit_app)
    problem = create(:errbit_problem, app: app)
    err = create(:errbit_err, problem: problem)
    notice = create(:errbit_notice, app: app, err: err)
    create(:errbit_notice, app: app, err: err)
    sign_in user

    visit app_problem_path(notice.app, notice.problem)

    expect(page).to have_css(".spark")
    expect(page).to have_css(".spark > i[class*='height-']")

    click_link "Older"

    expect(page).to have_css(".spark > i[class*='height-']")
  end

  it "toggles conditional application fields without inline styles" do
    allow(Errbit::Config).to receive(:per_app_email_at_notices).and_return(true)
    app = create(:errbit_app, notify_on_errs: false, notice_fingerprinter: nil)
    sign_in user

    visit edit_app_path(app)

    expect(page).to have_css(".email_at_notices_nested", visible: :hidden)
    check "Notify on errors"
    expect(page).to have_css(".email_at_notices_nested", visible: :visible)
    uncheck "Notify on errors"
    expect(page).to have_css(".email_at_notices_nested", visible: :hidden)
  end

  it "updates the app search without evaluating a JavaScript response" do
    create(:errbit_app, name: "Searchable Demo App")
    sign_in user

    visit apps_path
    fill_in "search", with: "Searchable"
    find("#search").send_keys(:enter)

    expect(page).to have_css("#app_table", text: "Searchable Demo App")
  end

  it "updates the problem search without evaluating a JavaScript response" do
    app = create(:errbit_app)
    create(:errbit_problem, app: app, message: "Searchable problem")
    create(:errbit_problem, app: app, message: "Other problem")
    sign_in user

    visit problems_path
    fill_in "search", with: "Searchable"
    find("#search").send_keys(:enter)

    expect(page).to have_css("#problem_table", text: "Searchable problem")
    expect(page).not_to have_css("#problem_table", text: "Other problem")

    check "toggle_problems_checkboxes"
    expect(page).to have_checked_field("problems[]")
  end
end
