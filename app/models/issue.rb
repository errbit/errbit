# frozen_string_literal: true

class Issue
  include ActiveModel::Model
  attr_accessor :problem, :user, :body

  def issue_tracker
    @issue_tracker ||= problem.app.issue_tracker
  end

  def tracker
    @tracker ||= issue_tracker && issue_tracker.tracker
  end

  def render_body_args
    if tracker.respond_to?(:render_body_args)
      tracker.render_body_args
    else
      ["issue_trackers/issue", formats: [:md]]
    end
  end

  def title
    if tracker.respond_to?(:title)
      tracker.title
    else
      "[#{problem.environment}][#{problem.where}] #{problem.message.to_s.truncate(100)}"
    end
  end

  def close
    errors.add :base, "This app has no issue tracker" unless issue_tracker
    return false if errors.present?

    tracker.errors.each { |k, err| errors.add k, err }
    return false if errors.present?

    if issue_tracker.respond_to? :close_issue
      issue_tracker.close_issue(problem.issue_link, user: user.as_document)
    end

    errors.empty?
  rescue => ex
    errors.add :base, "There was an error during issue closing: #{ex.message}"
    false
  end

  def save
    errors.add :base, "The issue has no body" unless body
    errors.add :base, "This app has no issue tracker" unless issue_tracker
    return false if errors.present?

    tracker.errors.each { |k, err| errors.add k, err }
    return false if errors.present?

    url = issue_tracker.create_issue(title, body, user: user.as_document)
    problem.update(issue_link: url, issue_type: tracker.class.label)

    errors.empty?
  rescue => ex
    errors.add :base, "There was an error during issue creation: #{ex.message}"
    false
  end
end
