class IssueTrackerDecorator < Draper::Decorator

  delegate_all

  def issue_trackers
    @issue_trackers ||= [
      IssueTracker::None,
      IssueTracker.subclasses.select{|klass| klass != IssueTracker::None }
    ].flatten
    @issue_trackers.each do |it|
      yield IssueTrackerDecorator.new(it)
    end
  end

  def note
    object::Note.html_safe
  end

  def fields
    object::Fields.each do |field, field_info|
      yield IssueTrackerFieldDecorator.new(field, field_info)
    end
  end

  def params_class(tracker)
    [choosen?(tracker), label].join(" ").strip
  end

  private

  def choosen?(issue_tracker)
    object.to_s == issue_tracker._type ? 'chosen' : ''
  end

end
