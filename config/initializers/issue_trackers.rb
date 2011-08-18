# Include nested issue tracker models
include IssueTrackers

# Require all issue tracker apis in lib/issue_tracker_apis
Dir.glob(Rails.root.join('lib/issue_tracker_apis/*.rb')).each {|t| require t }

