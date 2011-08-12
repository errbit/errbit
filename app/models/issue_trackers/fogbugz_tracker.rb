class FogbugzTracker < IssueTracker
  def self.label; "fogbugz"; end

  def check_params
    if %w(project_id account username password).detect {|f| self[f].blank? }
      errors.add :base, 'You must specify your FogBugz Area Name, FogBugz URL, Username, and Password'
    end
  end

  def create_issue(err)
    fogbugz = Fogbugz::Interface.new(:email => username, :password => password, :uri => "https://#{account}.fogbugz.com")
    fogbugz.authenticate

    issue = {}
    issue['sTitle'] = issue_title err
    issue['sArea'] = project_id
    issue['sEvent'] = body_template.result(binding)
    issue['sTags'] = ['errbit'].join(',')
    issue['cols'] = ['ixBug'].join(',')

    fb_resp = fogbugz.command(:new, issue)
    err.update_attribute :issue_link, "https://#{account}.fogbugz.com/default.asp?#{fb_resp['case']['ixBug']}"
  end

  def body_template
    @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/fogbugz_body.txt.erb"))
  end
end

