class IssueTrackers::LighthouseTracker < IssueTracker
  Label = "lighthouseapp"
  Fields = [
    [:account, {
      :placeholder => "abc from http://abc.lighthouseapp.com"
    }],
    [:api_token, {
      :placeholder => "API Token for your account"
    }],
    [:project_id, {
      :placeholder => "Lighthouse project"
    }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify your Lighthouseapp account, API token and Project ID'
    end
  end

  def create_issue(problem, reported_by = nil)
    Lighthouse.account = account
    Lighthouse.token = api_token
    # updating lighthouse account
    Lighthouse::Ticket.site
    Lighthouse::Ticket.format = :xml
    ticket = Lighthouse::Ticket.new(:project_id => project_id)
    ticket.title = issue_title problem

    ticket.body = body_template.result(binding)

    ticket.tags << "errbit"
    ticket.save!
    problem.update_attributes(
      :issue_link => "#{Lighthouse::Ticket.site.to_s.sub(/#{Lighthouse::Ticket.site.path}$/, '')}#{Lighthouse::Ticket.element_path(ticket.id, :project_id => project_id)}".sub(/\.xml$/, ''),
      :issue_type => Label
    )

  end

  def body_template
    @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/lighthouseapp_body.txt.erb").gsub(/^\s*/, ''))
  end

  def url
    "http://#{account}.lighthouseapp.com"
  end
end

