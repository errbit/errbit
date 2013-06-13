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

    def check_params
      if Fields.any? { |f, _| self[f].blank? }
        errors.add :base, 'You must specify your Flowdock(Flow) API token'
      end
    end

    def url
      'https://www.flowdock.com/session'
    end

    def create_notification(problem)
      flow = Flowdock::Flow.new(:api_token => api_token, :source => "Errbit", :from => {:name => "Errbit", :address => 'support@flowdock.com'})
      subject = "[#{problem.environment}] #{problem.message.to_s.truncate(100)}"
      url = app_problem_url problem.app, problem
      flow.push_to_team_inbox(:subject => subject, :content => content(problem, url), :project => project_name(problem), :link => url)
    end

    private

    # can only contain alphanumeric characters and underscores
    def project_name(problem)
      problem.app.name.gsub /[^0-9a-z_]/i, ''
    end

    def content(problem, url)
      full_description = "[#{ problem.environment }][#{ problem.where }] #{problem.message.to_s}"
      <<-MSG.strip_heredoc
        #{ERB::Util.html_escape full_description}<br>
        <a href="#{url}">#{url}</a>
      MSG
    end
  end
end
