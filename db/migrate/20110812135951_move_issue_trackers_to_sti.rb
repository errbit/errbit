class MoveIssueTrackersToSti < Mongoid::Migration
  def self.up
    App.all.each do |app|
      # Update all embedded issue trackers to use STI patterns.
      # All issue trackers now subclass the IssueTracker model,
      # and their class is stored in the '_type' field, which is
      # also aliased to 'type'.
      if app.issue_tracker && app.issue_tracker.attributes["issue_tracker_type"]
        app.issue_tracker._type = case app.issue_tracker.issue_tracker_type
        when 'lighthouseapp'; "LighthouseTracker"
        when 'redmine'; "RedmineTracker"
        when 'pivotal'; "PivotalLabsTracker"
        when 'fogbugz'; "FogbugzTracker"
        when 'mingle'; "MingleTracker"
        else; nil
        end
        if app.issue_tracker.issue_tracker_type == "none"
          app.issue_tracker = nil
        else
          app.issue_tracker.issue_tracker_type = nil
        end
        app.save
      end
    end
  end

  def self.down
  end
end

