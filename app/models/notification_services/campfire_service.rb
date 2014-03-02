if defined? Campy
  class NotificationServices::CampfireService < NotificationService
    Label = "campfire"
    Fields += [
      [:subdomain, {
        :label       => "Subdomain",
        :placeholder => "subdomain from http://{{subdomain}}.campfirenow.com"
      }],
      [:api_token, {
        :label       => "API Token",
        :placeholder => "123456789abcdef123456789abcdef"
      }],
      [:room_id, {
        :label       => "Room ID",
        :placeholder => "123456"
      }]
    ]

    def check_params
      if Fields.detect {|f| self[f[0]].blank? }
        errors.add :base, 'You must specify your Campfire Subdomain, API token and Room ID'
      end
    end

    def url
      "http://#{subdomain}.campfirenow.com/"
    end

    def create_notification(problem)
      campy = Campy::Room.new(:account => subdomain,
                              :token => api_token,
                              :room_id => room_id)
      campy.speak form_message(problem)
    end

    private

    def form_message(problem)
      "[errbit] #{problem.app.name} #{notification_description(problem)} - #{problem_url(problem)}"
    end
  end
end
