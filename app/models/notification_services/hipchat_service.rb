if defined? HipChat
  class NotificationServices::HipchatService < NotificationService
    LABEL = 'hipchat'
    FIELDS += [
      [:service, {
        placeholder: "'v1' (admin API token) or 'v2' (account API token)",
        label:       "HipChat API version"
      }],
      [:service_url, {
        placeholder: "Optional, leave empty for HipChat.com",
        label:       "Custom HipChat Server URL"
      }],
      [:api_token, {
        placeholder: "API token",
        label:       "API token"
      }],
      [:room_id, {
        placeholder: "Room name",
        label:       "Room name"
      }]
    ]
    MANDATORY_FIELDS = [:service, :api_token, :room_id]
    API_VERSIONS = %w(v1 v2)

    def check_params
      FIELDS.each do |field, hash|
        if MANDATORY_FIELDS.include?(field) && self[field].blank?
          errors.add field, "You must specify #{hash[:label]}"
        end
      end
      unless API_VERSIONS.include?(self[:service])
        errors.add :service, "API version must be #{API_VERSIONS.join(' or ')}"
      end
    end

    def url
      "https://www.hipchat.com/sign_in"
    end

    def create_notification(problem)
      url = app_problem_url problem.app, problem
      message = <<-MSG.strip_heredoc
        <strong>#{ERB::Util.html_escape problem.app.name}</strong> error in <strong>#{ERB::Util.html_escape problem.environment}</strong> at <strong>#{ERB::Util.html_escape problem.where}</strong> (<a href="#{url}">details</a>)<br>
        &nbsp;&nbsp;#{ERB::Util.html_escape problem.message.to_s.truncate(100)}<br>
        &nbsp;&nbsp;Times occurred: #{problem.notices_count}
      MSG

      options = { api_version: self[:service] }
      options[:server_url] = self[:service_url] if service_url.present?

      client = HipChat::Client.new(api_token, options)
      client[room_id].send('Errbit', message, color: 'red', notify: true)
    end
  end
end
