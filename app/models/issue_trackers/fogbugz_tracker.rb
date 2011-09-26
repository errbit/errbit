class IssueTrackers::FogbugzTracker < IssueTracker
  Label = "fogbugz"
  Fields = [
    [:project_id, {
      :label       => "Area Name"
    }],
    [:account, {
      :label       => "FogBugz URL",
      :placeholder => "abc from http://abc.fogbugz.com/"
    }],
    [:username, {
      :placeholder => "Username/Email for your account"
    }],
    [:password, {
      :placeholder => "Password for your account"
    }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify your FogBugz Area Name, FogBugz URL, Username, and Password'
    end
  end

  def create_issue(problem)
    fogbugz = Fogbugz::Interface.new(:email => username, :password => password, :uri => "https://#{account}.fogbugz.com")
    fogbugz.authenticate

    issue = {}
    issue['sTitle'] = issue_title problem
    issue['sArea'] = project_id
    issue['sEvent'] = body_template.result(binding)
    issue['sTags'] = ['errbit'].join(',')
    issue['cols'] = ['ixBug'].join(',')

    fb_resp = fogbugz.command(:new, issue)
    problem.update_attribute :issue_link, "https://#{account}.fogbugz.com/default.asp?#{fb_resp['case']['ixBug']}"
  end

  def body_template
    @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/fogbugz_body.txt.erb"))
  end
end

