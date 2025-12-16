# frozen_string_literal: true

class MailerPreview < ActionMailer::Preview
  def err_notification
    error_report = nil

    Mailer.err_notification(error_report)
  end

  def comment_notification
    user = FactoryBot.create(:user)
    # problem
    comment = FactoryBot.create(:comment, user: user)

    Mailer.comment_notification(comment)
  end
end
