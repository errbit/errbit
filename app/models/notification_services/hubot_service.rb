module NotificationServices
  class HubotService < NotificationService
    LABEL = "hubot"
    FIELDS += [
      [:api_token, {
        placeholder: "http://hubot.example.org:8080/hubot/say",
        label: "Hubot URL"
      }],
      [:room_id, {
        placeholder: "#dev",
        label: "Room where Hubot should notify"
      }]
    ]

    def check_params
      if FIELDS.detect { |f| self[f[0]].blank? }
        errors.add :base, "You must specify the URL of your hubot"
      end
    end

    def url
      api_token
    end

    def message_for_hubot(problem)
      "[#{problem.app.name}][#{problem.environment}][#{problem.where}]: #{problem.error_class} #{problem.url}"
    end

    def create_notification(problem)
      HTTParty.post(url, body: {message: message_for_hubot(problem), room: room_id})
    end
  end
end
