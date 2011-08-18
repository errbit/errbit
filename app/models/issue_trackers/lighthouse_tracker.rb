class LighthouseTracker < IssueTracker
  Label = "lighthouseapp"
  RequiredFields = %w(account api_token project_id)

  def check_params
    if RequiredFields.detect {|f| self[f].blank? }
      errors.add :base, 'You must specify your Lighthouseapp account, API token and Project ID'
    end
  end

  def create_issue(err)
    Lighthouse.account = account
    Lighthouse.token = api_token
    # updating lighthouse account
    Lighthouse::Ticket.site

    ticket = Lighthouse::Ticket.new(:project_id => project_id)
    ticket.title = issue_title err

    ticket.body = body_template.result(binding)

    ticket.tags << "errbit"
    ticket.save!
    err.update_attribute :issue_link, "#{Lighthouse::Ticket.site.to_s.sub(/#{Lighthouse::Ticket.site.path}$/, '')}#{Lighthouse::Ticket.element_path(ticket.id, :project_id => project_id)}".sub(/\.xml$/, '')
  end

  def body_template
    @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/lighthouseapp_body.txt.erb").gsub(/^\s*/, ''))
  end
end

