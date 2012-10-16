if defined? PivotalTracker
  class IssueTrackers::PivotalLabsTracker < IssueTracker
    Label = "pivotal"
    Fields = [
      [:api_token, {
        :placeholder => "API Token for your account"
      }],
      [:project_id, {}]
    ]

    def check_params
      if Fields.detect {|f| self[f[0]].blank? }
        errors.add :base, 'You must specify your Pivotal Tracker API token and Project ID'
      end
    end

    def create_issue(problem, reported_by = nil)
      PivotalTracker::Client.token = api_token
      PivotalTracker::Client.use_ssl = true
      project = PivotalTracker::Project.find project_id.to_i
      story = project.stories.create :name => issue_title(problem),
        :story_type => 'bug', :description => body_template.result(binding),
        :requested_by => reported_by.name

      if story.errors.present?
        raise IssueTrackers::IssueTrackerError, story.errors.first
      else
        problem.update_attributes(
          :issue_link => "https://www.pivotaltracker.com/story/show/#{story.id}",
          :issue_type => Label
        )
      end
    end

    def body_template
      @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/pivotal_body.txt.erb"))
    end

    def url
      "https://www.pivotaltracker.com/"
    end
  end
end