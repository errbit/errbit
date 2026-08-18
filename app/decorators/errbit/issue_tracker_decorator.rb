# frozen_string_literal: true

module Errbit
  class IssueTrackerDecorator < Draper::Decorator
    delegate_all

    def type
      @type ||= Errbit::IssueTrackerTypeDecorator.new(object.tracker.class)
    end
  end
end
