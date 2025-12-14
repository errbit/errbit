# frozen_string_literal: true

module Devise
  class MailerPreview < ActionMailer::Preview
    def confirmation_instructions
    end

    def reset_password_instructions
      user = FactoryBot.create(:user, reset_password_token: "token-123")

      @resource = user
      @token = user.reset_password_token
    end

    def unlock_instructions
    end

    def email_changed
    end

    def password_change
    end
  end
end
