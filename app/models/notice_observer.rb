class NoticeObserver < Mongoid::Observer
  observe :notice

  def after_create notice
    # if the app has a notification service, fire it off
    if notice.app.notification_service_configured?
      notice.app.notification_service.create_notification(notice.problem)
    end

    if notice.app.notification_recipients.any?
      Mailer.err_notification(notice).deliver
    end
  end

  private

  def should_notify? notice
    app = notice.app
    app.notify_on_errs? and (app.notification_recipients.any? or !app.notification_service.nil?) and
      (app.email_at_notices or Errbit::Config.email_at_notices).include?(notice.problem.notices_count)
  end
end
