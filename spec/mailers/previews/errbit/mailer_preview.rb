# frozen_string_literal: true

module Errbit
  class MailerPreview < ActionMailer::Preview
    def err_notification
      notice = FactoryBot.create(:errbit_notice)
      report = Struct.new(:notice, :app, :problem).new(notice, notice.app, notice.problem)

      Errbit::Mailer.with(error_report: report).err_notification
    end

    def comment_notification
      user = FactoryBot.create(:errbit_user)
      comment = FactoryBot.create(:errbit_comment, user: user)

      Errbit::Mailer.with(comment: comment).comment_notification
    end
  end
end
