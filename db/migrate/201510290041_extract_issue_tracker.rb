class ExtractIssueTracker < Mongoid::Migration
  TRACKER_MAPPING = {
    'ErrbitTracPlugin::IssueTracker'        => 'trac',
    'IssueTrackers::BitbucketIssuesTracker' => 'bitbucket',
    'IssueTrackers::FogbugzTracker'         => 'fogbugz',
    'IssueTrackers::GithubIssuesTracker'    => 'github',
    'IssueTrackers::GitlabTracker'          => 'gitlab',
    'IssueTrackers::JiraTracker'            => 'jira',
    'IssueTrackers::LighthouseTracker'      => 'lighthouse',
    'IssueTrackers::PivotalLabsTracker'     => 'pivotal',
    'IssueTrackers::RedmineTracker'         => 'redmine',
    'IssueTrackers::UnfuddleTracker'        => 'unfuddle'
  }

  def self.up
    App.all.each do |app|
      next unless app.attributes['issue_tracker'].present?
      next unless app.attributes['issue_tracker']['_type'].present?

      options = app['issue_tracker'].dup
      options.delete('_type')
      options.delete('_id')

      type = app.attributes['issue_tracker']['_type']
      updated_at = options.delete('updated_at')
      created_at = options.delete('created_at')

      next unless TRACKER_MAPPING.include?(type)

      tracker = {
        'type_tracker' => TRACKER_MAPPING[type],
        'options'      => options,
        'updated_at'   => updated_at,
        'created_at'   => created_at
      }

      App.where(_id: app.id).update("$set" => { issue_tracker: tracker })
    end
  end

  def self.down
  end
end
