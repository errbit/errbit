module IssueTrackers
  class IssueTrackerError < StandardError; end
  class AuthenticationError < IssueTrackerError; end
end
