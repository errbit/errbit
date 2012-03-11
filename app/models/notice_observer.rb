class NoticeObserver < Mongoid::Observer
  observe :notice

  def after_create notice
    return unless should_notify? notice

    Mailer.err_notification(notice).deliver
  end

  private

  def should_notify? notice
    app = notice.app
    app.notify_on_errs? &&
      (Errbit::Config.per_app_email_at_notices && app.email_at_notices || Errbit::Config.email_at_notices).include?(notice.problem.notices_count) &&
      app.notification_recipients.any?
  end

end
