require 'acceptance/acceptance_helper'

feature 'Sign in with GitHub' do

  background do
    Errbit::Config.stub(:github_authentication) { true }
    Fabricate(:user, :github_login => 'nashby')
  end

  scenario 'log in via GitHub with recognized user' do
    mock_auth('nashby')

    visit '/'
    click_link 'Sign in with GitHub'
    expect(page).to have_content I18n.t("devise.omniauth_callbacks.success", :kind => 'GitHub')
  end

  scenario 'reject unrecognized user if authenticating via GitHub' do
    mock_auth('unknown_user')

    visit '/'
    click_link 'Sign in with GitHub'
    expect(page).to have_content 'There are no authorized users with GitHub login'
  end
end
