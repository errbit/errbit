# frozen_string_literal: true

module Errbit
  class NoticeFingerprinter < ApplicationRecord
    belongs_to :app,
      class_name: "Errbit::App",
      foreign_key: :errbit_app_id,
      inverse_of: :notice_fingerprinter,
      optional: true

    def generate(api_key, notice, backtrace)
      material = [api_key]
      material << notice.error_class if error_class
      material << notice.filtered_message if message
      material << notice.component if component
      material << notice.action if action
      material << notice.environment_name if environment_name

      if backtrace
        material << if backtrace_lines.negative?
          backtrace.lines
        else
          backtrace.lines.slice(0, backtrace_lines)
        end
      end

      Digest::MD5.hexdigest(material.join)
    end
  end
end
