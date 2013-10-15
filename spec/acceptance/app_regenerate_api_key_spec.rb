require 'acceptance/acceptance_helper'

feature "Regeneration api_Key" do
  let!(:app) { Fabricate(:app) }
  let!(:admin) { Fabricate(:admin) }
  let(:user) {
    Fabricate(:user_watcher, :app => app).user
  }

  scenario "an admin change api_key" do
    visit '/'
    log_in admin
    click_link app.name
    click_link I18n.t('apps.show.edit')
    expect {
      click_link I18n.t('apps.fields.regenerate_api_key')
    }.to change {
      app.reload.api_key
    }
    click_link I18n.t('shared.navigation.apps')
    click_link I18n.t('apps.index.new_app')
    expect(page).to_not have_button I18n.t('apps.fields.regenerate_api_key')
  end

  scenario "a user cannot access to edit page" do
    visit '/'
    log_in user
    click_link app.name if page.current_url != app_url(app)
    expect(page).to_not have_button I18n.t('apps.show.edit')
  end

end
