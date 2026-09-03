# frozen_string_literal: true

module Errbit
  class IssueTrackerTypeDecorator < Draper::Decorator
    delegate_all

    def icons
      return unless object.icons

      object.icons.each_with_object({}) do |(key, value), icons|
        icons[key] = "data:#{value[0]};base64,#{Base64.encode64(value[1])}"
      end
    end

    def params_class(tracker)
      [(object.label == tracker.type_tracker) ? "chosen" : "", label].join(" ").strip
    end

    def note
      object.note.html_safe
    end

    def fields
      object.fields.each do |field, field_info|
        yield Errbit::IssueTrackerFieldDecorator.new(field, field_info)
      end
    end
  end
end
