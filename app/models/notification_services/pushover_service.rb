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
    # build the hoi client
    notification = Rushover::Client.new(subdomain)

    # send push notification to pushover
    notification.notify(api_token, "#{notification_description problem}", :priority => 1, :title => "Errbit Notification", :url => "http://#{Errbit::Config.host}/apps/#{problem.app.id.to_s}", :url_title => "Link to error")

  end
end
