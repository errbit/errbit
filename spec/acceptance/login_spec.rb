require 'acceptance/acceptance_helper'

feature 'Log in' do
  background do
    Errbit::Config.stub(:github_authentication) { true }
    Fabricate(:user, :github_login => 'nashby')
  end

  scenario 'log in via Github' do
    visit '/'
    click_link 'Sign in with Github'
    page.should have_content 'Successfully authorized from Github account'
  end
end
