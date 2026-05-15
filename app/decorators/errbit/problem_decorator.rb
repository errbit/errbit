# frozen_string_literal: true

module Errbit
  class ProblemDecorator < Draper::Decorator
    decorates_association :notices
    delegate_all
  end
end
