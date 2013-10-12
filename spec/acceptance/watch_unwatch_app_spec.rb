require 'acceptance/acceptance_helper'

feature 'A user can watch and unwatch an application' do

  let!(:app) { Fabricate(:app) }
  let!(:user) do
    user = Fabricate(:user)
    app.watchers.create!(
      :user_id => user.id
    )
    user.reload
  end

  scenario 'log in watch a project and unwatch it' do
    log_in user
    click_on I18n.t('apps.show.unwatch')
    expect(page).to have_content(I18n.t('apps.index.no_apps'))
  end

end
