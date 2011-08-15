class Mailer < ActionMailer::Base
  default :from => Errbit::Config.email_from
  
  def err_notification(notice)
    @notice   = notice
    @app      = notice.app
    
    mail({
      :to       => @app.notification_recipients,
      :subject  => "[#{@app.name}][#{@notice.err.environment}] #{@notice.err.message}"
    })
  end
  
  def deploy_notification(deploy)
    @deploy   = deploy
    @app      = deploy.app
    
    mail({
      :to       => @app.notification_recipients,
      :subject  => "[#{@app.name}] Deployed to #{@deploy.environment} by #{@deploy.username}"
    })
  end

end

