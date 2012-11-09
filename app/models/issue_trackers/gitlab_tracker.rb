if defined? Gitlab
  class IssueTrackers::GitlabTracker < IssueTracker
    Label = "gitlab"
    Fields = [
      [:account, {
        :label       => "Gitlab URL",
        :placeholder => "e.g. https://example.net"
      }],
      [:api_token, {
        :placeholder => "API Token for your account"
      }],
      [:project_id, {
        :label       => "Ticket Project Short Name / ID",
        :placeholder => "Gitlab Project where issues will be created"
      }]
    ]

    def check_params
      if Fields.detect {|f| self[f[0]].blank?}
        errors.add :base, 'You must specify your Gitlab URL, API token and Project ID'
      end
    end

    def create_issue(problem, reported_by = nil)
      Gitlab.configure do |config|
        config.endpoint = "#{account}/api/v2"
        config.private_token = api_token
        config.user_agent = 'Errbit User Agent'
      end
      title = issue_title problem
      description = body_template.result(binding)
      Gitlab.create_issue(project_id, title, { :description => description, :labels => "errbit" } )
    end

    def body_template
      @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/gitlab_body.txt.erb").gsub(/^\s*/, ''))
    end
    
    def url
      "#{account}/#{project_id}/issues"
    end
  end
end
