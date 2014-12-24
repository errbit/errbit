class Issue
  include ActiveModel::Model
  attr_accessor :issue_tracker, :user, :title, :body

  def intialize(issue_tracker: nil, user: nil, title: nil, body: nil)
    @issue_tracker, @user, @title, @body = issue_tracker, user, title, body
  end

  def save
    if issue_tracker
      issue_tracker.create_issue(title, body, user.as_document)
    else
      errors.add :base, "This app has no issue tracker setup."
    end
    errors.empty?
  rescue => ex
    errors.add :base, "There was an error during issue creation: #{ex.message}"
    false
  end
end
