# Require all issue tracker apis in lib/issue_tracker_apis
Dir.glob(Rails.root.join('lib/issue_trackers/apis/*.rb')).each {|t| require t }
# Require issue tracker error classes
require Rails.root.join('lib/issue_trackers/errors')

# Include nested issue tracker models
include IssueTrackers
