# frozen_string_literal: true

require "rails_helper"

RSpec.describe "A user can watch and unwatch an application", type: :system, retry: 3 do
  context "when user signs in and watches a project" do
    it "creates a watcher for the app" do
      current_user = create(:errbit_user)
      app = create(:errbit_app)

      sign_in(current_user)

      visit root_path

      click_link app.name
      click_link I18n.t("apps.show.watch")

      expect(page).to have_content(I18n.t("watchers.create.success", app: app.name))
    end
  end

  context "when user signs in and unwatches a project" do
    it "destroys their existing watcher on the app" do
      current_user = create(:errbit_user)
      app = create(:errbit_app)

      app.watchers.create!(user: current_user)

      sign_in(current_user)

      visit root_path

      click_link app.name
      click_link I18n.t("apps.show.unwatch")

      expect(page).to have_content(I18n.t("watchers.destroy.success", app: app.name))
    end
  end
end
