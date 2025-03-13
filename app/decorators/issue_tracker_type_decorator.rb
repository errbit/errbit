# Decorates an IssueTracker class
class IssueTrackerTypeDecorator < Draper::Decorator
  delegate_all

  # return hash of icons as data URIs
  def icons
    return unless object.icons

    object.icons.reduce({}) do |c, (k, v)|
      c[k] = "data:#{v[0]};base64,#{Base64.encode64(v[1])}"
      c
    end
  end

  # class name for tracker type form fields
  #
  # 'chosen github' or 'bitbucket' for example
  def params_class(tracker)
    [object.label == tracker.type_tracker ? "chosen" : "", label].join(" ").strip
  end

  def note
    object.note.html_safe
  end

  def fields
    object.fields.each do |field, field_info|
      yield IssueTrackerFieldDecorator.new(field, field_info)
    end
  end
end
