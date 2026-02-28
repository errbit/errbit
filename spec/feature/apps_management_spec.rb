# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin manages applications", type: :feature, retry: 3 do
  let!(:admin) { create(:user, admin: true) }

  before { sign_in(admin) }

  it "views the apps index page" do
    app = create(:app, name: "My Test App")

    visit apps_path

    expect(page).to have_content("My Test App")
    expect(page).to have_link(I18n.t("apps.index.new_app"))
  end

  it "creates a new app" do
    visit new_app_path

    fill_in "Name", with: "Brand New App"
    click_button I18n.t("apps.new.add_app")

    expect(page).to have_content(I18n.t("controllers.apps.flash.create.success"))
    expect(page).to have_content("Brand New App")
    expect(page).to have_content(I18n.t("apps.show.api_key"))
  end

  it "views app details page" do
    data = create_app_with_problem(name: "Detail App")
    app = data[:app]

    visit app_path(app)

    expect(page).to have_content("Detail App")
    expect(page).to have_content(app.api_key)
    expect(page).to have_content(I18n.t("apps.show.errors_caught"))
  end

  it "edits an app" do
    app = create(:app, name: "Old Name")

    visit edit_app_path(app)

    fill_in "Name", with: "Updated Name"
    click_button I18n.t("apps.edit.update")

    expect(page).to have_content(I18n.t("controllers.apps.flash.update.success"))
    expect(page).to have_content("Updated Name")
  end

  it "regenerates API key" do
    app = create(:app, name: "Regen App")
    old_api_key = app.api_key

    visit edit_app_path(app)

    expect(page).to have_content(old_api_key)

    click_link I18n.t("apps.fields.regenerate_api_key")

    app.reload
    expect(app.api_key).not_to eq(old_api_key)
  end

  it "deletes an app" do
    app = create(:app, name: "Doomed App")

    visit edit_app_path(app)

    accept_confirm(I18n.t("apps.confirm_delete")) do
      click_link "delete application"
    end

    expect(page).to have_content(I18n.t("controllers.apps.flash.destroy.success"))
    expect(page).to have_current_path(apps_path)
  end
end
