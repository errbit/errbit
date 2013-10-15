if defined? JIRA
  class IssueTrackers::JiraTracker < IssueTracker
    Label = 'jira'

    Fields = [
        [:base_url, {
            :label => 'Jira URL without trailing slash',
            :placeholder => 'https://jira.example.org/'
        }],
        [:context_path, {
            :optional => true,
            :label => 'Context Path (Just "/" if empty otherwise with leading slash)',
            :placeholder => "/jira"
        }],
        [:username, {
            :optional => true,
            :label => 'HTTP Basic Auth User',
            :placeholder => 'johndoe'
        }],
        [:password, {
            :optional => true,
            :label => 'HTTP Basic Auth Password',
            :placeholder => 'p@assW0rd'
        }],
        [:project_id, {
            :label => 'Project Key',
            :placeholder => 'The project Key where the issue will be created'
        }],
        [:account, {
            :optional => true,
            :label => 'Assign to this user. If empty, Jira takes the project default.',
            :placeholder => "username"
        }],
        [:issue_component, {
            :label => 'Issue category',
            :placeholder => 'Website - Other'
        }],
        [:issue_type, {
            :label => 'Issue type',
            :placeholder => 'Bug'
        }],
        [:issue_priority, {
            :label => 'Priority',
            :placeholder => 'Normal'
        }]
    ]

    def check_params
      if Fields.detect { |f| self[f[0]].blank? && !f[1][:optional] }
        errors.add :base, 'You must specify all non optional values!'
      end
    end


    #
    # @param problem Problem
    def create_issue(problem, reported_by = nil)
      options = {
          :username => username,
          :password => password,
          :site => base_url,
          :context_path => context_path,
          :auth_type => :basic,
          :use_ssl => base_url.match(/^https/) ? true : false
      }
      client = JIRA::Client.new(options)

      issue = {
          :fields => {
              :project => {
                  :key => project_id
              },
              :summary => issue_title(problem),
              :description => body_template.result(binding),
              :issuetype => {
                  :name => issue_type
              },
              :priority => {
                  :name => issue_priority,
              }
          }
      }

      #might be able to use delimeter to have multiple
      issue[:fields][:components] = [{:name => issue_component}] if issue_component.present?

      issue[:fields][:assignee] = {:name => account} if account

      issue_build = client.Issue.build
      issue_build.save(issue)
      issue_build.fetch

      problem.update_attributes(
          :issue_link => "#{base_url}#{context_path}browse/#{issue_build.key}",
          :issue_type => Label
      )

      # Maybe in a later version?
      #remote_link = {
      #    :url => app_problem_url(problem.app, problem),
      #    :name => "Link to Errbit Issue"
      #}
      #remote_link_build = issue_build.remotelink.build
      #remote_link_build.save(remote_link)
    end

    def body_template
      @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/jira_body.txt.erb"))
    end
  end
end