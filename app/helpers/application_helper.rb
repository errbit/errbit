module ApplicationHelper
  def lighthouse_tracker? object
    object.issue_tracker_type == "lighthouseapp"
  end
end
