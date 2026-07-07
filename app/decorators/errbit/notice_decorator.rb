# frozen_string_literal: true

module Errbit
  class NoticeDecorator < Draper::Decorator
    decorates_association :backtrace
    delegate_all
  end
end
