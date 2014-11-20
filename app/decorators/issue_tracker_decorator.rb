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
