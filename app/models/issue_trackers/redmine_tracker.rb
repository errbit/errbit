class IssueTrackers::RedmineTracker < IssueTracker
  Label = "redmine"
  RequiredFields = %w(account api_token project_id)

  def check_params
    if RequiredFields.detect {|f| self[f].blank? }
      errors.add :base, 'You must specify your Redmine URL, API token and Project ID'
    end
  end

  def create_issue(err)
    token = api_token
    acc = account
    RedmineClient::Base.configure do
      self.token = token
      self.site = acc
    end
    issue = RedmineClient::Issue.new(:project_id => project_id)
    issue.subject = issue_title err
    issue.description = body_template.result(binding)
    issue.save!
    err.update_attribute :issue_link, "#{RedmineClient::Issue.site.to_s.sub(/#{RedmineClient::Issue.site.path}$/, '')}#{RedmineClient::Issue.element_path(issue.id, :project_id => project_id)}".sub(/\.xml\?project_id=#{project_id}$/, "\?project_id=#{project_id}")
  end

  def body_template
    @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/textile_body.txt.erb"))
  end
end

