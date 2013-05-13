# Haml doesn't load routes automatically when called via a rake task.
# This is only necessary when sending test emails (i.e. from rake hoptoad:test)
require Rails.root.join('config/routes.rb')

class Mailer < ActionMailer::Base
  helper ApplicationHelper
  helper BacktraceLineHelper

  default :from => Errbit::Config.email_from

  def err_notification(notice)
    @notice   = notice
    @app      = notice.app

    count = @notice.similar_count
    count = count > 1 ? "(#{count}) " : ""

    mail :to      => @app.notification_recipients,
         :subject => "#{count}[#{@app.name}][#{@notice.environment_name}] #{@notice.message.truncate(50)}"
  end

  def deploy_notification(deploy)
    @deploy   = deploy
    @app  = deploy.app

    mail :to       => @app.notification_recipients,
         :subject  => "[#{@app.name}] Deployed to #{@deploy.environment} by #{@deploy.username}"
  end

  def comment_notification(comment)
    @comment  = comment
    @user     = comment.user
    @problem  = comment.err
    @notice   = @problem.notices.first
    @app      = @problem.app

    recipients = @comment.notification_recipients

    mail :to      => recipients,
         :subject => "#{@user.name} commented on [#{@app.name}][#{@notice.environment_name}] #{@notice.message.truncate(50)}"
  end
end
