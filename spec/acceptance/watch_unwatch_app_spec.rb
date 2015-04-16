require 'acceptance/acceptance_helper'

feature 'A user can watch and unwatch an application' do

  let!(:app) { Fabricate(:app) }
  let!(:user) { Fabricate(:user) }

  scenario 'log in and watch a project' do
    log_in user
    click_on app.name

    click_on I18n.t('apps.show.watch')

    expect(page).to have_content(I18n.t('controllers.watchers.flash.create.success', :app_name => app.name))
    expect(app.reload.watchers.where(:user_id => user.id)).not_to be_empty
  end

  scenario 'log in and unwatch a project' do
    app.watchers.create!(
      :user_id => user.id
    )

    log_in user
    click_on I18n.t('apps.show.unwatch')
    expect(page).to have_content("That's sad. #{user.name} is no longer watcher.")
    expect(app.reload.watchers.where(:user_id => user.id)).to be_empty
  end
end
