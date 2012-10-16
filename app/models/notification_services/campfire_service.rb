if defined? Campy
  class NotificationServices::CampfireService < NotificationService
    Label = "campfire"
    Fields = [
        [:subdomain, {
            :placeholder => "Campfire Subdomain"
        }],
        [:api_token, {
            :placeholder => "API Token"
        }],
        [:room_id, {
            :placeholder => "Room ID",
            :label       => "Room ID"
        }],
    ]

    def check_params
      if Fields.detect {|f| self[f[0]].blank? }
        errors.add :base, 'You must specify your Campfire Subdomain, API token and Room ID'
      end
    end

    def create_notification(problem)
      # build the campfire client
      campy = Campy::Room.new(:account => subdomain, :token => api_token, :room_id => room_id)

      # post the issue to the campfire room
      campy.speak "[errbit] #{problem.app.name} #{notification_description problem} - http://#{Errbit::Config.host}/apps/#{problem.app.id.to_s}/problems/#{problem.id.to_s}"
    end
  end
end
