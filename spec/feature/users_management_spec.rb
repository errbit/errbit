# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin manages users", type: :feature, retry: 3 do
  let!(:admin) { create(:user, admin: true, name: "Admin User") }

  before { sign_in(admin) }

  it "views the users index" do
    other_user = create(:user, name: "Jane Doe", admin: false)

    visit users_path

    expect(page).to have_content("Admin User")
    expect(page).to have_content("Jane Doe")
    expect(page).to have_link(I18n.t("users.index.new"))
  end

  it "creates a new user" do
    visit new_user_path

    fill_in I18n.t("users.fields.name"), with: "New Member"
    fill_in I18n.t("users.fields.email"), with: "newmember@example.com"
    fill_in I18n.t("users.fields.password"), with: "password123"
    fill_in I18n.t("users.fields.password_confirmation"), with: "password123"

    click_button I18n.t("users.new.add_user")

    expect(page).to have_content(I18n.t("users.create.success", name: "New Member"))
  end

  it "views a user profile" do
    user = create(:user, name: "Profile User", email: "profile@example.com", admin: false)

    visit user_path(user)

    expect(page).to have_content("Profile User")
    expect(page).to have_content("profile@example.com")
    expect(page).to have_content("No")
  end

  it "edits a user" do
    user = create(:user, name: "Old Name", password: "password123")

    visit edit_user_path(user)

    fill_in I18n.t("users.fields.name"), with: "New Name"
    fill_in I18n.t("users.fields.password"), with: "password123"
    fill_in I18n.t("users.fields.password_confirmation"), with: "password123"

    click_button I18n.t("users.edit.update_user")

    expect(page).to have_content(I18n.t("users.update.success", name: "New Name"))
  end

  it "deletes a user" do
    user = create(:user, name: "Departing User")

    visit user_path(user)

    accept_confirm(I18n.t("users.show.confirm_delete")) do
      click_link I18n.t("users.show.destroy")
    end

    expect(page).to have_content(I18n.t("users.destroy.success", name: "Departing User"))
  end
end
