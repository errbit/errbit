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
        :label       => "Ticket Project ID (use Number)",
        :placeholder => "Gitlab Project where issues will be created"
      }],
      [:alt_project_id, {
        :label       => "Project Name (namespace/project)",
        :placeholder => "Gitlab Project where issues will be created"
      }]
    ]

    def check_params
      if Fields.detect {|f| self[f[0]].blank?}
        errors.add :base, 'You must specify your Gitlab URL, API token, Project ID and Project Name'
      end
    end

    def create_issue(problem, reported_by = nil)
      Gitlab.configure do |config|
        config.endpoint = "#{account}/api/v3"
        config.private_token = api_token
        config.user_agent = 'Errbit User Agent'
      end
      title = issue_title problem
      description_summary = summary_template.result(binding)
      description_body = body_template.result(binding)
      ticket = Gitlab.create_issue(project_id, title, { :description => description_summary, :labels => "errbit" } )
      Gitlab.create_issue_note(project_id, ticket.id, description_body)
    end

    def summary_template
      @@summary_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/gitlab_summary.txt.erb").gsub(/^\s*/, ''))
    end

    def body_template
      @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/gitlab_body.txt.erb").gsub(/^\s*/, ''))
    end

    def url
      "#{account}/#{alt_project_id}/issues"
    end
  end
end
