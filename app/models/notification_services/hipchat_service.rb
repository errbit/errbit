class NotificationServices::HipchatService < NotificationService
  Label = 'hipchat'
  Fields = [
    [:api_token, {
      :placeholder => "API Token"
    }],
    [:room_id, {
      :placeholder => "Room ID",
      :label       => "Room ID"
    }],
  ]

  def check_params
    if Fields.any? { |f, _| self[f].blank? }
      errors.add :base, 'You must specify your Hipchat API token and Room ID'
    end
  end

  def create_notification(problem)
    url = app_err_url problem.app, problem
    message = <<-MSG.strip_heredoc
      [#{ERB::Util.html_escape problem.app.name}]#{ERB::Util.html_escape notification_description(problem)}<br>
      <a href="#{url}">#{url}</a>
    MSG

    client = HipChat::Client.new(api_token)
    client[room_id].send('Errbit', message, :color => 'red')
  end
end
