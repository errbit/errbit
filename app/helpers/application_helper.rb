module ApplicationHelper
  def lighthouse_tracker? object
    object.issue_tracker_type == "lighthouseapp"
  end

  def redmine_tracker? object
    object.issue_tracker_type == "redmine"
  end

  def pivotal_tracker? object
    object.issue_tracker_type == "pivotal"
  end
end
