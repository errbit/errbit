class MoveIssueTrackersToSti < Mongoid::Migration
  def self.up
    App.all.each do |app|
      # Update all embedded issue trackers to use STI patterns.
      # All issue trackers now subclass the IssueTracker model,
      # and their class is stored in the '_type' field, which is
      # also aliased to 'type'.
      tracker = app.attributes['issue_tracker']
      if tracker && tracker['issue_tracker_type']
        tracker['_type'] = case tracker['issue_tracker_type']
        when 'lighthouseapp'; "IssueTrackers::LighthouseTracker"
        when 'redmine'; "IssueTrackers::RedmineTracker"
        when 'pivotal'; "IssueTrackers::PivotalLabsTracker"
        when 'fogbugz'; "IssueTrackers::FogbugzTracker"
        when 'mingle'; "IssueTrackers::MingleTracker"
        else; nil
        end

        if tracker['issue_tracker_type'] == "none"
          App.collection.where({ _id: app.id }).update({
            "$unset" => { :issue_tracker => 1 }
          })
        else
          tracker.delete('issue_tracker_type')
          App.collection.where({ _id: app.id }).update({
            "$set" => { :issue_tracker => tracker }
          })
        end
      end
    end
  end

  def self.down
  end
end

