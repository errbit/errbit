if defined? Flowdock
  class NotificationServices::FlowdockService < NotificationService
    Label = 'flowdock'
    Fields += [
      [
        :api_token, {
          :label       => 'Flow API Token',
          :placeholder => '123456789abcdef123456789abcdefgh'
        }
      ]
    ]

    def create_notification(message_info)
      flow = Flowdock::Flow.new(api_token: api_token,
                                source: 'Errbit',
                                from: { name: 'Errbit',
                                  address: address })

      flow.push_to_team_inbox(subject: form_subject(message_info),
                              content: form_message(message_info),
                              project: project_name(message_info),
                              link: form_url(message_info))
    end

    def url
      'https://www.flowdock.com/session'
    end

    def check_params
      if Fields.any? { |f, _| self[f].blank? }
        errors.add :base, 'You must specify your Flowdock(Flow) API token'
      end
    end

    private

    def address
      ENV['ERRBIT_EMAIL_FROM'] || 'support@flowdock.com'
    end

    def problem_subject(problem)
      "[#{problem.environment}] #{problem.message.to_s.truncate(100)}"
    end

    def problem_message(problem)
      full_description = "[#{ problem.environment }][#{ problem.where }] #{problem.message.to_s}"
      prob_url = problem_url(problem)
      <<-MSG.strip_heredoc
        #{ERB::Util.html_escape(full_description)}<br>
        <a href="#{prob_url}">#{prob_url}</a>
      MSG
    end

    # can only contain alphanumeric characters and underscores
    def project_name(message_info)
      message_info.app.name.gsub /[^0-9a-z_]/i, ''
    end
  end
end
