class AppDecorator < Draper::Decorator
  decorates_association :watchers
  decorates_association :issue_tracker, with: IssueTrackerDecorator
  delegate_all

  def email_at_notices
    object.email_at_notices.join(', ')
  end

  def notify_user_display
    object.notify_all_users ? 'display: none;' : ''
  end

  def notify_err_display
    object.notify_on_errs ? '' : 'display: none;'
  end
end
