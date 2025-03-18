# frozen_string_literal: true

class NoticeDecorator < Draper::Decorator
  decorates_association :backtrace
  delegate_all
end
