class Issue
  include ActiveModel::Model
  attr_accessor :problem, :user, :title, :body

  def intialize(problem: nil, user: nil, title: nil, body: nil)
    @problem, @user, @title, @body = problem, user, title, body
  end

  def save
    if tracker
      tracker.create_issue(title, body, user.as_document)
    else
      errors.add :base, "This app has no issue tracker setup."
    end
    errors.empty?
  rescue => ex
    errors.add :base, "There was an error during issue creation: #{ex.message}"
    false
  end

  def tracker
    problem.app.issue_tracker
  end
end
