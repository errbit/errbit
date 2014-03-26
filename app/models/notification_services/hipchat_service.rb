if defined? HipChat
  class NotificationServices::HipchatService < NotificationService
    Label = 'hipchat'
    Fields += [
      [:api_token, {
        :placeholder => 'API Token'
      }],
      [:room_id, {
        :placeholder => 'Room name',
        :label       => 'Room name'
      }],
    ]

    def url
      'https://www.hipchat.com/sign_in'
    end

    def create_notification(message_info)
      message = form_message(message_info)

      client = HipChat::Client.new(api_token)
      client[room_id].send('Errbit', message, :color => 'red')
    end

    def check_params
      if Fields.any? { |f, _| self[f].blank? }
        errors.add :base, 'You must specify your Hipchat API token and Room ID'
      end
    end

    private

    def problem_message(problem)
      <<-MSG.strip_heredoc
        <strong>#{ERB::Util.html_escape problem.app.name}</strong> error in <strong>#{ERB::Util.html_escape problem.environment}</strong> at <strong>#{ERB::Util.html_escape problem.where}</strong> (<a href="#{problem_url(problem)}">details</a>)<br>
        &nbsp;&nbsp;#{ERB::Util.html_escape problem.message.to_s.truncate(100)}<br>
        &nbsp;&nbsp;Times occurred: #{problem.notices_count}
      MSG
    end
  end
end
