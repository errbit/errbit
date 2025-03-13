require "acceptance/acceptance_helper"

feature "Regeneration api_Key" do
  let(:app) { Fabricate(:app) }
  let(:admin) { Fabricate(:admin) }
  let(:user) do
    Fabricate(:user_watcher, app: app).user
  end

  before do
    app && admin
  end

  scenario "an admin change api_key" do
    visit "/"
    log_in admin
    click_link app.name
    click_link I18n.t("apps.show.edit")
    expect do
      click_link I18n.t("apps.fields.regenerate_api_key")
    end.to change {
      app.reload.api_key
    }
    click_link I18n.t("shared.navigation.apps")
    click_link I18n.t("apps.index.new_app")
    expect(page).to_not have_button I18n.t("apps.fields.regenerate_api_key")
  end

  scenario "a user cannot access to edit page" do
    visit "/"
    log_in user
    click_link app.name if page.current_url != app_url(app)
    expect(page).to_not have_button I18n.t("apps.show.edit")
  end
end

feature "Create an application" do
  let(:admin) { Fabricate(:admin) }
  let(:user) do
    Fabricate(:user_watcher, app: app).user
  end

  before do
    admin
  end

  scenario "create an apps without issue tracker and edit it" do
    visit "/"
    log_in admin
    click_on I18n.t("apps.index.new_app")
    fill_in "app_name", with: "My new app"
    click_on I18n.t("apps.new.add_app")
    page.has_content?(I18n.t("controllers.apps.flash.create.success"))
    expect(App.where(name: "My new app").count).to eq 1
    expect(App.where(name: "My new app 2").count).to eq 0

    click_on I18n.t("shared.navigation.apps")
    click_on "My new app"
    click_link I18n.t("apps.show.edit")
    fill_in "app_name", with: "My new app 2"
    click_on I18n.t("apps.edit.update")
    page.has_content?(I18n.t("controllers.apps.flash.update.success"))
    expect(App.where(name: "My new app").count).to eq 0
    expect(App.where(name: "My new app 2").count).to eq 1
  end

  scenario "create an apps with issue tracker and edit it", js: true do
    visit "/"
    log_in admin
    click_on I18n.t("apps.index.new_app")
    fill_in "app_name", with: "My new app"
    find(".label_radio.github").click

    fill_in "app_github_repo", with: "foo/bar"
    within ".github.tracker_params" do
      fill_in "app_issue_tracker_attributes_options_username", with: "token"
      fill_in "app_issue_tracker_attributes_options_password", with: "pass"
    end
    click_on I18n.t("apps.new.add_app")
    expect(page.has_content?(I18n.t("controllers.apps.flash.create.success"))).to eql true
    app = App.where(name: "My new app").first
    expect(app.issue_tracker.type_tracker).to eql "github"
    expect(app.issue_tracker.options["username"]).to eql "token"
    expect(app.issue_tracker.options["password"]).to eql "pass"

    click_on I18n.t("shared.navigation.apps")
    click_on "My new app"
    click_link I18n.t("apps.show.edit")
    find(".issue_tracker .label_radio.none").click
    click_on I18n.t("apps.edit.update")
    expect(page.has_content?(I18n.t("controllers.apps.flash.update.success"))).to eql true
    app = App.where(name: "My new app").first
    expect(app.issue_tracker.tracker).to be_a ErrbitPlugin::NoneIssueTracker
  end
end
