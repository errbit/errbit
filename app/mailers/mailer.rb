# Haml doesn't load routes automatically when called via a rake task.
# This is only necessary when sending test emails (i.e. from rake hoptoad:test)
require Rails.root.join("config/routes.rb")

class Mailer < ActionMailer::Base
  helper ApplicationHelper

  default :from                      => Errbit::Config.email_from,
          "X-Errbit-Host"            => Errbit::Config.host,
          "X-Mailer"                 => "Errbit",
          "X-Auto-Response-Suppress" => "OOF, AutoReply",
          "Precedence"               => "bulk",
          "Auto-Submitted"           => "auto-generated"

  def err_notification(error_report)
    @notice   = NoticeDecorator.new error_report.notice
    @app      = AppDecorator.new error_report.app

    count = error_report.problem.notices_count
    count = count > 1 ? "(#{count}) " : ""

    errbit_headers "App"         => @app.name,
                   "Environment" => @notice.environment_name,
                   "Error-Id"    => @notice.err_id

    mail to:      @app.notification_recipients,
         subject: "#{count}[#{@app.name}][#{@notice.environment_name}] #{@notice.message.truncate(50)}"
  end

  def comment_notification(comment)
    @comment  = comment
    @user     = comment.user
    @problem  = ProblemDecorator.new comment.err
    @notice   = NoticeDecorator.new comment.err.notices.first
    @app      = @problem.app

    recipients = @comment.notification_recipients

    errbit_headers "App"            => @app.name,
                   "Environment"    => @notice.environment_name,
                   "Problem-Id"     => @problem.id,
                   "Comment-Author" => @user.name

    mail to:      recipients,
         subject: "#{@user.name} commented on [#{@app.name}][#{@notice.environment_name}] #{@notice.message.truncate(50)}"
  end

private

  def errbit_headers(header)
    header.each { |key, value| headers["X-Errbit-#{key}"] = value.to_s }
  end
end
