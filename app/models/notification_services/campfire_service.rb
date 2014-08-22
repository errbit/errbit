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
      # build the campfire client
      campy = Campy::Room.new(:account => subdomain, :token => api_token, :room_id => room_id)
      # post the issue to the campfire room
      campy.speak "[errbit] #{problem.app.name} #{notification_description problem} - #{Errbit::Config.protocol}://#{Errbit::Config.host}/apps/#{problem.app.id.to_s}/problems/#{problem.id.to_s}"
    end
  end
end
