# frozen_string_literal: true

module Errbit
  class ProblemDecorator < Draper::Decorator
    decorates_association :notices, with: Errbit::NoticeDecorator
    delegate_all
  end
end
