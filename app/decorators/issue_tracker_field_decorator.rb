class IssueTrackerFieldDecorator < Draper::Decorator

  def initialize(field, field_info)
    @object = field
    @field_info = field_info
  end
  attr_reader :object, :field_info

  alias :key :object

  def label
    field_info[:label] || object.to_s.titleize
  end


  def input(form)
    form.send(input_field, object,
              :placeholder => field_info[:placeholder],
              :value => form.object.send(object))
  end

  private

  def input_field
    object == :password ? :password_field : :text_field
  end
end
