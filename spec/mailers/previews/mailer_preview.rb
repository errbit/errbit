# frozen_string_literal: true

class MailerPreview < ActionMailer::Preview
  def err_notification
    app = App.new(name: "Demo App")
    problem = Problem.new(app: app, notices_count: 5)
    notice = Notice.new(
      app: app,
      problem: problem,
      message: "RuntimeError: Something went wrong",
      environment_name: "production",
      err_id: BSON::ObjectId.new.to_s
    )
    error_report = OpenStruct.new(notice: notice, app: app, problem: problem)

    Mailer.with(error_report: error_report).err_notification
  end

  def comment_notification
    user = FactoryBot.create(:user)
    # problem
    comment = FactoryBot.create(:comment, user: user)

    Mailer.with(comment: comment).comment_notification
  end
end
