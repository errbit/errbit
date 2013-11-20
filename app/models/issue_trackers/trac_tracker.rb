if defined? Trac
  class IssueTrackers::TracTracker < IssueTracker
    Label = 'trac'

    Fields = [
      [:base_url, {
        :label => 'Trac Project URL (without /xmlrpc)',
        :placeholder => 'http://www.example.com/trac/project'
      }],
      [:username, {
        :label => 'Trac User',
        :placeholder => 'johndoe'
      }],
      [:password, {
        :label => 'Trac Password',
        :placeholder => 'p@assW0rd'
      }],
      [:issue_type, {
        :label => 'Type of issue to create',
        :placeholder => 'defect'
      }],
    ]

    def check_params
      if Fields.detect { |f| self[f[0]].blank? && !f[1][:optional] }
        errors.add :base, 'You must specify all values!'
      end
    end

    # Checks to see if this issue tracker is configured
    #
    # @return [TrueClass]
    def project_id
      true
    end

    # @param problem Problem
    def create_issue(problem, reported_by = nil)
      if reported_by
        reporter = reported_by.name
      else
        reporter = "errbit"
      end

      client = Trac.new(base_url, username, password)

      ticket_id = client.tickets.create(issue_title(problem), body_template.result(binding), {
        :type => issue_type,
        :reporter => reporter,
        :keywords => "errbit",
      })

      problem.update_attributes(
        :issue_link => link_for_issue(ticket_id),
        :issue_type => Label
      )
    end

    def link_for_issue(ticket_id)
      url = base_url

      # if it ends in /, remove the /
      if matches = /(.*)\/$/.match(base_url)
        url = matches[1]
      end

      "%s/ticket/%s" % [base_url, ticket_id]
    end

    def body_template
      @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/trac_body.txt.erb"))
    end
  end
end
