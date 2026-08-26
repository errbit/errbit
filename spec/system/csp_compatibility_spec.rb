# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CSP-compatible browser behavior", type: :system, retry: 3 do
  let!(:user) { create(:user, admin: true) }

  it "loads the notice sparkline" do
    app = create(:app)
    problem = create(:problem, app: app)
    err = create(:err, problem: problem)
    notice = create(:notice, app: app, err: err)
    create(:notice, app: app, err: err)
    sign_in user

    visit app_problem_path(notice.app, notice.problem)

    expect(page).to have_css(".spark")
    expect(page).to have_css(".spark > i[class*='height-']")

    click_link "Older"

    expect(page).to have_css(".spark > i[class*='height-']")
  end

  it "toggles conditional application fields without inline styles" do
    allow(Errbit::Config).to receive(:per_app_email_at_notices).and_return(true)
    app = create(:app, notify_on_errs: false, notice_fingerprinter: nil)
    sign_in user

    visit edit_app_path(app)

    expect(page).to have_css(".email_at_notices_nested", visible: :hidden)
    check "Notify on errors"
    expect(page).to have_css(".email_at_notices_nested", visible: :visible)
    uncheck "Notify on errors"
    expect(page).to have_css(".email_at_notices_nested", visible: :hidden)
  end
end
