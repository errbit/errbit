class DeployObserver < Mongoid::Observer
  observe :deploy

  def after_create deploy
    return unless deploy.app.notify_on_deploys? && deploy.app.notification_recipients.any?

    Mailer.deploy_notification(deploy).deliver
  end
end
