# Haml doesn't load routes automatically when called via a rake task.
# This is only necessary when sending test emails (i.e. from rake hoptoad:test)
require Rails.root.join('config/routes.rb')

class Mailer < ActionMailer::Base
  helper ApplicationHelper
  helper BacktraceLineHelper

  default :from => Errbit::Config.email_from,
          'X-Errbit-Host' => Errbit::Config.host,
          'X-Mailer' => 'Errbit',
          'X-Auto-Response-Suppress' => 'OOF, AutoReply',
          'Precedence' => 'bulk',
          'Auto-Submitted' => 'auto-generated'

  def err_notification(notice)
    @notice   = notice
    @app      = notice.app

    count = @notice.similar_count
    count = count > 1 ? "(#{count}) " : ""

    errbit_headers 'App' => @app.name,
                   'Environment' => @notice.environment_name,
                   'Error-Id' => @notice.err_id

    mail :to      => @app.notification_recipients,
         :subject => "#{count}[#{@app.name}][#{@notice.environment_name}] #{@notice.message.truncate(50)}"
  end

  def deploy_notification(deploy)
    @deploy   = deploy
    @app  = deploy.app

    errbit_headers 'App' => @app.name,
                   'Environment' => @deploy.environment,
                   'Deploy-Revision' => @deploy.revision,
                   'Deploy-User' => @deploy.username

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

    errbit_headers 'App' => @app.name,
                   'Environment' => @notice.environment_name,
                   'Problem-Id' => @problem.id,
                   'Comment-Author' => @user.name

    mail :to      => recipients,
         :subject => "#{@user.name} commented on [#{@app.name}][#{@notice.environment_name}] #{@notice.message.truncate(50)}"
  end

  private

  def errbit_headers(header)
    header.each { |key,value| headers["X-Errbit-#{key}"] = value.to_s }
  end
end
