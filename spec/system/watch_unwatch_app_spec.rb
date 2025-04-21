# frozen_string_literal: true

require "rails_helper"

RSpec.describe "A user can watch and unwatch an application", type: :system do
  let!(:user) { create(:user) }

  # let!(:app) { create(:app) }

  context "log in and watch a project" do
    it "is expected to log in and watch a project" do
      app = create(:app)

      sign_in(user)

      visit root_path

      click_link app.name
      click_link I18n.t("apps.show.watch")

      expect(page).to have_content(I18n.t("watchers.update.success", app: app.name))
    end
  end

  context "log in and unwatch a project" do
    it "is expected to log in and unwatch a project" do
      app = create(:app)

      app.watchers.create!(user: user)

      sign_in(user)

      visit root_path

      click_link app.name
      click_link I18n.t("apps.show.unwatch")

      expect(page).to have_content(I18n.t("watchers.destroy.success", app: app.name))
    end
  end
end
