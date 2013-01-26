class NotificationServices::HubotService < NotificationService
  Label = "hubot"
  Fields = [
    [:api_token, {
      :placeholder => 'http://hubot.example.org:8080/hubot/say',
      :label => 'Hubot URL'
    }],
    [:room_id, {
      :placeholder => '#dev',
      :label => 'Room where Hubot should notify'
    }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify the URL of your hubot'
    end
  end

  def url
    api_token
  end

  def message_for_hubot(problem)
    notification_description(problem)
  end

  def create_notification(problem)

    Faraday.post(url, :message => message_for_hubot(problem), :room => room_id)
    # send push notification to pushover
    #notification.notify(api_token, "#{notification_description problem}", :priority => 1, :title => "Errbit Notification", :url => "http://#{Errbit::Config.host}/apps/#{problem.app.id.to_s}", :url_title => "Link to error")

  end
end

