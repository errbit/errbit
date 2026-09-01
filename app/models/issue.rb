# frozen_string_literal: true

class Issue
  include ActiveModel::Model

  attr_accessor :problem, :user, :body

  def issue_tracker
    @issue_tracker ||= problem.app.issue_tracker
  end

  def tracker
    @tracker ||= issue_tracker&.tracker
  end

  # The body is the markup the issue tracker gets, so it has to render bare.
  # Without this, render_to_string wraps it in the Errbit page layout and the
  # issue ends up holding a whole HTML document.
  def render_body_args
    args =
      if tracker.respond_to?(:render_body_args)
        tracker.render_body_args
      else
        [{template: "issue_trackers/markdown"}]
      end

    return args + [{layout: false}] unless args.last.is_a?(Hash)

    args[0..-2] + [{layout: false}.merge(args.last)]
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
  rescue => e
    errors.add :base, "There was an error during issue closing: #{e.message}"

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
  rescue => e
    errors.add :base, "There was an error during issue creation: #{e.message}"

    false
  end
end
