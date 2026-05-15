# frozen_string_literal: true

module Errbit
  class ProblemDecorator < Draper::Decorator
    # `Errbit::Notice.model_name` is overridden to "Notice" (for routes/views).
    # Draper would otherwise resolve `decorates_association :notices` to the
    # un-namespaced Mongoid `NoticeDecorator`. Pin it explicitly.
    decorates_association :notices, with: Errbit::NoticeDecorator
    delegate_all
  end
end
