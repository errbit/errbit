class IssueCreation
  include ActiveModel::Validations

  attr_reader :problem, :user, :tracker_name

  delegate :app, :to => :problem

  def initialize(problem, user, tracker_name)
    @problem = problem
    @user    = user
    @tracker_name = tracker_name
  end

  def tracker
    return @tracker if @tracker

    # Create an issue on GitHub using user's github token
    if tracker_name == 'user_github'
      if !app.github_repo?
        errors.add :base, "This app doesn't have a GitHub repo set up."
      elsif !user.github_account?
        errors.add :base, "You haven't linked your Github account."
      else
        @tracker = GithubIssuesTracker.new(
          :app         => app,
          :username    => user.github_login,
          :oauth_token => user.github_oauth_token
        )
      end

    # Or, create an issue using the App's issue tracker
    elsif app.issue_tracker_configured?
      @tracker = app.issue_tracker

    # Otherwise, display error about missing tracker configuration.
    else
      errors.add :base, "This app has no issue tracker setup."
    end

    @tracker
  end

  def execute
    tracker.create_issue problem, user if tracker
    errors.empty?
  rescue => ex
    Rails.logger.error "Error during issue creation: " << ex.message
    errors.add :base, "There was an error during issue creation: #{ex.message}"
    false
  end
end
