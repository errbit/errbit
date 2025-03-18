# frozen_string_literal: true

class IssueTrackerFieldDecorator < Draper::Decorator
  def initialize(field, field_info)
    @object = field
    @field_info = field_info
  end
  attr_reader :object, :field_info

  alias_method :key, :object

  def label
    field_info[:label] || object.to_s.titleize
  end

  def input(form, issue_tracker)
    form.send(input_field, key.to_s,
      placeholder: field_info[:placeholder],
      value: issue_tracker.options[key.to_s])
  end

  private

  def input_field
    (object == :password) ? :password_field : :text_field
  end
end
