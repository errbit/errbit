class AppDecorator < Draper::Decorator
  decorates_association :watchers
  decorates_association :issue_tracker, with: IssueTrackerDecorator
  delegate_all

  def email_at_notices
    object.email_at_notices.join(', ')
  end

  def use_site_fingerprinter
    if object.notice_fingerprinter.nil? || object.notice_fingerprinter.attributes['source'].nil?
      true
    else
      object.notice_fingerprinter.attributes['source'] == SiteConfig::CONFIG_SOURCE_SITE
    end
  end

  def custom_notice_fingerprinter_style
    use_site_fingerprinter ? 'display: none' : 'display: inline'
  end

  def notify_user_display
    object.notify_all_users ? 'display: none;' : ''
  end

  def notify_err_display
    object.notify_on_errs ? '' : 'display: none;'
  end
end
