# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User manages comments on problems", type: :feature, retry: 3 do
  let!(:user) { create(:user) }

  before { sign_in(user) }

  it "adds a comment to a problem" do
    data = create_app_with_problem
    app = data[:app]
    problem = data[:problem]

    visit app_problem_path(app, problem)

    fill_in "comment[body]", with: "This looks like a known issue."
    click_button I18n.t("problems.show.save_comment")

    expect(page).to have_content(I18n.t("comments.create.success"))
    expect(page).to have_content("This looks like a known issue.")
  end
end
