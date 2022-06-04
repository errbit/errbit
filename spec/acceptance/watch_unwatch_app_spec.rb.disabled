require 'acceptance/acceptance_helper'

feature 'A user can watch and unwatch an application' do
  let!(:app) { Fabricate(:app) }
  let!(:user) { Fabricate(:user) }

  scenario 'log in and unwatch a project' do
    app.watchers.create!(user_id: user.id)
    user.reload

    log_in user
    click_on app.name
    click_on I18n.t('apps.show.unwatch')
    expect(page).to have_content(
      I18n.t('watchers.destroy.success', app: app.name))
  end

  scenario 'log in and watch a project' do
    log_in user
    click_on app.name
    click_on I18n.t('apps.show.watch')
    expect(page).to have_content(
      I18n.t('watchers.update.success', app: app.name))
  end
end
