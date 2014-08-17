class NotificationServices::HubotService < NotificationService
  Label = "hubot"
  Fields += [
    [:api_token, {
      :placeholder => 'http://hubot.example.org:8080/hubot/say',
      :label => 'Hubot URL'
    }],
    [:room_id, {
      :placeholder => '#dev',
      :label => 'Room where Hubot should notify'
    }]
  ]

  def url
    api_token
  end

  def create_notification(message_info)
    HTTParty.post(url,
                  :body => { :message => form_message(message_info),
                    :room => room_id })
  end

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify the URL of your hubot'
    end
  end

  private

  def problem_message(problem)
    "[#{problem.app.name}][#{problem.environment}][#{problem.where}]: #{problem.error_class} #{problem_url(problem)}"
  end
end

