class IssueTrackers::GithubIssuesTracker < IssueTracker
  Label = "github"
  Note = 'Please configure your github repository in the <strong>GITHUB REPO</strong> field above.<br/>' <<
         'Instead of providing your username & password, you can link your Github account ' <<
         'to your user profile, and allow Errbit to create issues using your OAuth token.'

  Fields = [
    [:username, {
      :placeholder => "Your username on GitHub"
    }],
    [:password, {
      :placeholder => "Password for your account"
    }]
  ]

  attr_accessor :oauth_token

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify your GitHub repository, username and password'
    end
  end

  def create_issue(problem, reported_by = nil)
    # Login using OAuth token, if given.
    if oauth_token
      client = Octokit::Client.new(:login => username, :oauth_token => oauth_token)
    else
      client = Octokit::Client.new(:login => username, :password => password)
    end

    begin
      issue = client.create_issue(app.github_repo, issue_title(problem), body_template.result(binding).unpack('C*').pack('U*'), options = {})
      problem.update_attribute :issue_link, issue.html_url
    rescue Octokit::Unauthorized
      raise IssueTrackers::AuthenticationError, "Could not authenticate with GitHub. Please check your username and password."
    end
  end

  def body_template
    @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/github_issues_body.txt.erb").gsub(/^\s*/, ''))
  end

  def url
    "https://github.com/#{app.github_repo}/issues"
  end
end
