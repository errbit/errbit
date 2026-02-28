# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User works with problems", type: :feature, retry: 3 do
  let!(:admin) { create(:user, admin: true) }

  before { sign_in(admin) }

  it "views the global problems index" do
    data = create_app_with_problem(name: "Problem App")
    problem = data[:problem]

    visit problems_path

    expect(page).to have_content(I18n.t("problems.index.unresolved_errors"))
    expect(page).to have_content("Problem App")
    expect(page).to have_content(problem.error_class)
  end

  it "views app-scoped problems" do
    data = create_app_with_problem(name: "Scoped App")
    app = data[:app]

    visit app_path(app)

    expect(page).to have_content("Scoped App")
    expect(page).to have_content(I18n.t("apps.show.errors"))
  end

  it "views problem detail page" do
    data = create_app_with_problem(name: "Detail App")
    app = data[:app]
    problem = data[:problem]

    visit app_problem_path(app, problem)

    expect(page).to have_content(problem.error_class)
    expect(page).to have_content(problem.environment)
    expect(page).to have_link(I18n.t("problems.show.summary"))
    expect(page).to have_link(I18n.t("problems.show.backtrace"))
  end

  it "resolves a problem from the detail page" do
    data = create_app_with_problem(name: "Resolve App")
    app = data[:app]
    problem = data[:problem]

    visit app_problem_path(app, problem)

    accept_confirm(I18n.t("problems.confirm.resolve_one")) do
      click_link I18n.t("problems.show.resolve")
    end

    expect(page).to have_content(I18n.t("problems.resolve.the_error_has_been_resolved"))
  end

  it "toggles between unresolved and all errors" do
    data = create_app_with_problem(name: "Toggle App")
    data[:problem].resolve!

    visit problems_path

    expect(page).to have_content(I18n.t("problems.index.unresolved_errors"))

    click_link I18n.t("problems.index.show_resolved")

    expect(page).to have_content(I18n.t("problems.index.all_errors"))
    expect(page).to have_content("Toggle App")
  end
end
