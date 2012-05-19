class IssueTrackers::GithubIssuesTracker < IssueTracker
  Label = "github"
  Fields = [
    [:project_id, {
      :label       => "Account/Repository",
      :placeholder => "errbit/errbit from https://github.com/errbit/errbit"
    }],
    [:username, {
      :placeholder => "Your username on Github"
    }],
    [:password, {
      :placeholder => "Password for your account"
    }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify your Github repository, username and password'
    end
  end

  def create_issue(err)
    client = Octokit::Client.new(:login => username, :password => password)
    issue = client.create_issue(project_id, issue_title(err), body_template.result(binding).unpack('C*').pack('U*'), options = {})
    err.update_attribute :issue_link, issue.issue.html_url
  end

  def body_template
    @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/github_issues_body.txt.erb").gsub(/^\s*/, ''))
  end
end

