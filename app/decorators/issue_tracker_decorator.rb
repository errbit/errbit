# frozen_string_literal: true

class IssueTrackerDecorator < Draper::Decorator
  delegate_all

  def type
    @type ||= IssueTrackerTypeDecorator.new(object.tracker.class)
  end
end
