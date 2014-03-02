class NotificationServices::PushoverService < NotificationService
  Label = "pushover"
  Fields += [
      [:api_token, {
          :placeholder => "User Key",
          :label => "User Key"
      }],
      [:subdomain, {
          :placeholder => "Application API Token",
          :label => "Application API Token"
      }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify your User Key and Application API Token.'
    end
  end

  def url
    "https://pushover.net/login"
  end

  def create_notification(problem)
    notification = Rushover::Client.new(subdomain)

    notification.notify(api_token,
                        notification_description(problem),
                        priority: 1,
                        title: 'Errbit Notification',
                        url: problem_url(problem),
                        url_title: 'Link to error')
  end
end
