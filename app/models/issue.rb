class Issue
  include ActiveModel::Model
  attr_accessor :problem, :user, :title, :body

  def issue_tracker
    problem.app.issue_tracker
  end

  def save
    unless body
      errors.add :base, "The issue has no body"
      return false
    end

    unless title
      errors.add :base, "The issue has no title"
      return false
    end

    if issue_tracker
      issue_tracker.tracker.errors.each do |k, err|
        errors.add k, err
      end
      return false if errors.present?

      url = issue_tracker.create_issue(title, body, user: user.as_document)
      problem.update_attributes(issue_link: url, issue_type: issue_tracker.tracker.class.label)
    else
      errors.add :base, "This app has no issue tracker setup."
    end

    errors.empty?
  rescue => ex
    errors.add :base, "There was an error during issue creation: #{ex.message}"
    false
  end
end
