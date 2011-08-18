class GithubTracker < IssueTracker
  Label = "github"
  RequiredFields = %w(project_id username api_token)

  def check_params
    if RequiredFields.detect {|f| self[f].blank? }
      errors.add :base, 'You must specify your Github repository, username and API token'
    end
  end

  def create_issue(err)
    client = Octokit::Client.new(:login => username, :token => api_token)
    issue = client.create_issue(project_id, issue_title(err), body_template.result(binding), options = {})
    err.update_attribute :issue_link, issue.html_url
  end

  def body_template
    @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/github_body.txt.erb").gsub(/^\s*/, ''))
  end
end

