require 'acceptance/acceptance_helper'

feature 'Sign in with SAML' do
  background do
    allow(Errbit::Config).to receive(:saml_authentication).and_return(true)
    Fabricate(:user, email: 'known@example.com')
    visit root_path
  end

  scenario 'log in via SAML with recognized user' do
    mock_auth('known@example.com')

    click_link 'Sign in with SAML'
    expect(page).to have_content I18n.t('devise.omniauth_callbacks.success', kind: 'SAML')
  end

  scenario 'login and create unrecognized user if authenticating via SAML' do
    mock_auth('unknown@example.com')

    click_link 'Sign in with SAML'
    expect(page).to have_content I18n.t('devise.omniauth_callbacks.success', kind: 'SAML')
  end
end
