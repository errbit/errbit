class ProblemDecorator < Draper::Decorator
  decorates_association :notices
  delegate_all

  def link_text
    object.message.presence || object.error_class
  end
end
