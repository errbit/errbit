# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User watches and unwatches apps", type: :feature, retry: 3 do
  let!(:user) { create(:user) }

  before { sign_in(user) }

  it "watches an app" do
    app = create(:app, name: "Watchable App")

    visit app_path(app)

    click_link I18n.t("apps.show.watch")

    expect(page).to have_content(I18n.t("watchers.create.success", app: "Watchable App"))
  end

  it "unwatches an app" do
    app = create(:app, name: "Unwatchable App")
    app.watchers.create!(user: user)

    visit app_path(app)

    click_link I18n.t("apps.show.unwatch")

    expect(page).to have_content(I18n.t("watchers.destroy.success", app: "Unwatchable App"))
  end
end
