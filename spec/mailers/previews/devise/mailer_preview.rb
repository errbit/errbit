# frozen_string_literal: true

module Devise
  class MailerPreview < ActionMailer::Preview
    def reset_password_instructions
      record = FactoryBot.create(:user, reset_password_token: "reset-password-token")

      token = record.reset_password_token

      Devise::Mailer.reset_password_instructions(record, token)
    end
  end
end
