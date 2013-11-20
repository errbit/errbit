class IssueTrackerDecorator < Draper::Decorator

  def initialize(object, key)
    @object = object
    @key = key
  end
  attr_reader :key

  delegate_all

  def issue_trackers
    @issue_trackers ||= ErrbitPlugin::Register.issue_trackers
    @issue_trackers.each do |key, it|
      yield IssueTrackerDecorator.new(it.new(app, {}), key)
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
    [choosen?(tracker), label].join(" ").strip
  end

  private

  def choosen?(issue_tracker)
    key == issue_tracker.type_tracker.to_s ? 'chosen' : ''
  end

end
