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

  def url
    "https://pushover.net/login"
  end

  def create_notification(message_info)
    notification = Rushover::Client.new(subdomain)

    notification.notify(api_token,
                        form_description(message_info),
                        priority: 1,
                        title: 'Errbit Notification',
                        url: form_url(message_info),
                        url_title: 'Link to error or depoy')
  end

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify your User Key and Application API Token.'
    end
  end
end
