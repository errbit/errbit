require 'acceptance/acceptance_helper'

feature 'Sign in with Google' do
  background do
    allow(Errbit::Config).to receive(:google_authentication).and_return(true)
    Fabricate(:user, google_uid: 'nashby')
    visit root_path
  end

  scenario 'log in via Google with recognized user' do
    mock_auth('nashby')

    click_link 'Sign in with Google'
    expect(page).to have_content I18n.t('devise.omniauth_callbacks.success', kind: 'Google')
  end

  scenario 'reject unrecognized user if authenticating via Google' do
    mock_auth('unknown_user')

    click_link 'Sign in with Google'
    expect(page).to have_content 'There are no authorized users with Google login'
  end
end
