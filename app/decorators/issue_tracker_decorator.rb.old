# frozen_string_literal: true

# Decorates an instance of IssueTracker
class IssueTrackerDecorator < Draper::Decorator
  delegate_all

  def type
    @type ||= IssueTrackerTypeDecorator.new(object.tracker.class)
  end
end
