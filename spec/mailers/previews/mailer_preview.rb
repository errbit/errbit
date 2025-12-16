# frozen_string_literal: true

class MailerPreview < ActionMailer::Preview
  def err_notification
    error_report = nil

    Mailer.with(error_report: error_report).err_notification
  end

  def comment_notification
    user = FactoryBot.create(:user)
    # problem
    comment = FactoryBot.create(:comment, user: user)

    Mailer.with(comment: comment).comment_notification
  end
end
