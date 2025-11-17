# frozen_string_literal: true

class ProblemDecorator < Draper::Decorator
  decorates_association :notices
  delegate_all
end
