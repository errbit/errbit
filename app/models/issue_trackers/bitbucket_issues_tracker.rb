begin
  require 'bitbucket_rest_api'
rescue LoadError
end

if defined? BitBucket
  class IssueTrackers::BitbucketIssuesTracker < IssueTracker
    Label = "bitbucket"
    Note = 'Please configure your Bitbucket repository in the <strong>BITBUCKET REPO</strong> field above.'
    Fields = [
      [:api_token, {
        :placeholder => "Your username on Bitbucket account",
        :label => "Username"
      }],
      [:project_id, {
        :placeholder => "Password for your Bitbucket account",
        :label => "Password"
      }]
    ]

    def check_params
      if Fields.detect {|f| self[f[0]].blank? }
        errors.add :base, 'You must specify your Bitbucket username and password'
      end
    end

    def repo_name
      app.bitbucket_repo
    end

    def create_issue(problem, reported_by = nil)
      bitbucket = BitBucket.new :basic_auth => "#{api_token}:#{project_id}"

      begin
        r_user = repo_name.split('/')[0]
        r_name = repo_name.split('/')[1]
        issue = bitbucket.issues.create r_user, r_name, :title => issue_title(problem), :content => body_template.result(binding), :priority => 'critical'
        problem.update_attributes(
          :issue_link => "https://bitbucket.org/#{repo_name}/issue/#{issue.local_id}/",
          :issue_type => Label
        )
      rescue BitBucket::Error::Unauthorized
        raise IssueTrackers::AuthenticationError, "Could not authenticate with BitBucket. Please check your username and password."
      end
    end

    def body_template
      @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/bitbucket_issues_body.txt.erb"))
    end

    def url
      "https://www.bitbucket.org/#{repo_name}/issues"
    end
  end
end
