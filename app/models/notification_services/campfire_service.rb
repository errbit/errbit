if defined? Campy
  class NotificationServices::CampfireService < NotificationService
    Label = "campfire"
    Fields = [
      [:subdomain, {
        :label       => "Campfire Subdomain",
        :placeholder => "example"
      }],
      [:api_token, {
        :label       => "API Token",
        :placeholder => "1aa1111a111111aaaa11a11a1111a11a11111a11"
      }],
      [:room_id, {
        :label       => "Room ID number",
        :placeholder => "123456"
      }]
    ]

    def check_params
      if Fields.detect {|f| self[f[0]].blank? }
        errors.add :base, 'You must specify your Campfire Subdomain, API token and Room ID'
      end
    end

    def url
      "http://campfirenow.com/"
    end

    def create_notification(problem)
      # build the campfire client
      campy = Campy::Room.new(:account => subdomain, :token => api_token, :room_id => room_id)
      # post the issue to the campfire room
      campy.speak "[errbit] #{problem.app.name} #{notification_description problem} - http://#{Errbit::Config.host}/apps/#{problem.app.id.to_s}/problems/#{problem.id.to_s}"
    end
  end
end
