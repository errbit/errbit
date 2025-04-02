# frozen_string_literal: true

# require "capybara/rspec"

def log_in(user)
  visit "/"
  fill_in :user_email, with: user.email
  fill_in :user_password, with: "password"
  click_on I18n.t("devise.sessions.new.sign_in")
end
