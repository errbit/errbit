class NotificationServices::GtalkService < NotificationService
  Label = "gtalk"
  Fields = [
      [:subdomain, {
          :placeholder => "username@example.com",
          :label       => "Username"
      }],
      [:api_token, {
          :placeholder => "password",
          :label       => "Password"
      }],
      [:room_id, {
          :placeholder => "touser@example.com",
          :label       => "Send To User"
      }],
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify your Username, Password and To User'
    end
  end

  def url
    "http://www.google.com/talk/"
  end

  def create_notification(problem)
    # build the xmpp client
    client = Jabber::Client.new(Jabber::JID.new(subdomain))
    client.connect("talk.google.com")
    client.auth(api_token)

    # post the issue to the xmpp room
    client.send(Jabber::Message.new(room_id, "[errbit] http://#{Errbit::Config.host}/apps/#{problem.app.id.to_s} #{notification_description problem}"))
  end
end