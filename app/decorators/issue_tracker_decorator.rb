class IssueTrackerDecorator < Draper::Decorator

  def initialize(object, key)
    @object = object
    @key = key
  end
  attr_reader :key

  delegate_all

  def issue_trackers
    ErrbitPlugin::Registry.issue_trackers.each do |key, object|
      yield IssueTrackerDecorator.new(object, key)
    end
  end

  def icons
    tracker_icons = object.icons
    return unless tracker_icons

    tracker_icons.reduce({}) do |c, (k,v)|
      c[k] = "data:#{v[0]};base64,#{Base64.encode64(v[1])}"; c
    end
  end

  def note
    object.note.html_safe
  end

  def fields
    object.fields.each do |field, field_info|
      yield IssueTrackerFieldDecorator.new(field, field_info)
    end
  end

  def params_class(tracker)
    [chosen?(tracker), label].join(" ").strip
  end

  private

  def chosen?(issue_tracker)
    key == issue_tracker.type_tracker.to_s ? 'chosen' : ''
  end

end
