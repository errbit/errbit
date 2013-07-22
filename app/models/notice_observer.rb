class NoticeObserver < Mongoid::Observer
  observe :notice

  def after_create notice
    # if the app has a notification service, fire it off
    if notice.app.notification_service_configured? and notice.should_notify?
      notice.app.notification_service.create_notification(notice.problem)
    end

    Mailer.err_notification(notice).deliver if notice.should_email?
  end

end
