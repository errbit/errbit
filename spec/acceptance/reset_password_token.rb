require 'acceptance/acceptance_helper'

feature 'password reset token' do
  let(:user) { Fabricate :user }

  scenario 'receives correct password reset token' do
    host = ActionMailer::Base.default_url_options.values_at(:host).first
    port = ActionMailer::Base.default_url_options.values_at(:port).first
    port = port.blank? ? '' : ':' + port
    regex = %r{http://#{host}#{port}/users/password/edit\?reset_password_token=([A-Za-z0-9\-_]+)}

    visit 'https://brighterr.herokuapp.com/users/password/new'
    fill_in 'Email', with: user.email
    click_button 'Send me reset password instructions'
    expect(page).to have_content I18n.t('devise.passwords.send_instructions')

    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to match(/Reset password instructions/)
    expect(mail.body.encoded).to_not be_empty
    expect(mail.body.encoded).to match(/change your password/)
    expect(mail.body.encoded).to match(regex)
    if mail.body.encoded =~ regex
      visit "/users/password/edit?reset_password_token=#{$1}"
      expect(page).to have_content 'Change your password'
      fill_in 'New password', with: 'test12345'
      fill_in 'Type your new password again', with: 'test12345'
      click_button 'Change my password'
      expect(page).to_not have_content 'Reset password token is invalid'
    end
  end
end
