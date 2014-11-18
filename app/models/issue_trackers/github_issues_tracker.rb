if defined? Octokit
  class IssueTrackers::GithubIssuesTracker < IssueTracker
    Label = "github"
    Note = 'Please configure your github repository in the <strong>GITHUB REPO</strong> field above.<br/>' <<
           'Instead of providing your Access Token, you can link your Github account ' <<
           'to your user profile, and allow Errbit to create issues using your OAuth token.'

    Fields = [
      [:api_token, {
        :placeholder => "Access Token for your account"
      }],
    ]

    attr_accessor :oauth_token

    def project_id
      app.github_repo
    end

    def check_params
      if Fields.detect {|f| self[f[0]].blank? }
        errors.add :base, 'You must specify your GitHub Access Token'
      end
    end

    def create_issue(problem, reported_by = nil)
      # Login using OAuth token, if given.
      if oauth_token
        client = Octokit::Client.new(:access_token => oauth_token)
      else
        client = Octokit::Client.new(:access_token => api_token)
      end

      begin
        issue = client.create_issue(
          project_id,
          issue_title(problem),
          body_template.result(binding).unpack('C*').pack('U*')
        )
        problem.update_attributes(
          :issue_link => issue.rels[:html].href,
          :issue_type => Label
        )

      rescue Octokit::Unauthorized
        raise IssueTrackers::AuthenticationError, "Could not authenticate with GitHub. Please check your Access Token."
      end
    end

    def body_template
      @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/github_issues_body.txt.erb").gsub(/^\s*/, ''))
    end

    def url
      "https://github.com/#{project_id}/issues"
    end
  end
end
