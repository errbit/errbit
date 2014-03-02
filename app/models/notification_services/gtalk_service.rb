class NotificationServices::GtalkService < NotificationService
  Label = "gtalk"
  Fields += [
      [:subdomain, {
          :placeholder => "username@example.com",
          :label       => "Username"
      }],
      [:api_token, {
          :placeholder => "password",
          :label       => "Password"
      }],
      [:user_id, {
           :placeholder => "touser@example.com, anotheruser@example.com",
           :label => "Send To User(s)"
       }, :room_id],
      [:room_id, {
          :placeholder => "toroom@conference.example.com",
          :label       =>  "Send To Room (one only)"
      }, :user_id],
      [ :service, {
          :placeholder => "talk.google.com",
          :label => "Jabber Service"
      }],
      [ :service_url, {
          :placeholder => "http://www.google.com/talk/",
          :label => "Link To Jabber Service"
      }]
  ]

  def check_params
    if Fields.detect { |f| self[f[0]].blank? && self[f[2]].blank? }
      errors.add :base, <<-ERR.strip_heredoc.chomp
        You must specify your Username, Password, service, service_url
        and either rooms or users to send to or both
      ERR
    end
  end

  def url
    service_url || 'http://www.google.com/talk/'
  end

  def create_notification(problem)
    client = Jabber::Client.new(Jabber::JID.new(subdomain))
    client.connect(service)
    client.auth(api_token)

    message = form_message(problem)
    send_to_users(client, message) unless user_id.blank?
    send_to_muc(client, message) unless room_id.blank?
  end

  private

  def form_message(problem)
    <<-MSG.strip_heredoc.chomp
      #{problem.app.name}
      #{problem_url(problem)}
      #{notification_description(problem)}
    MSG
  end

  def send_to_users client, message
    user_id.gsub(/\s|;/, ',').split(',').each do |user|
      client.send(Jabber::Message.new(user, message)) unless user.blank?
    end
  end

  def send_to_muc client, message
    # TODO: set this so that it can send to multiple rooms like users,
    # multiple room joins in one send fail randomly so leave as one room for the moment
    muc = Jabber::MUC::SimpleMUCClient.new(client)
    muc.join(room_id + '/errbit')
    muc.send(Jabber::Message.new(room_id, message))
  end
end
