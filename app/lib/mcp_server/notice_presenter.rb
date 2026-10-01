# frozen_string_literal: true

module McpServer
  class NoticePresenter
    MAX_STRING_LENGTH = 500

    class << self
      def full(notice)
        metadata(notice).merge(
          data(notice).merge(backtrace: notice.backtrace&.lines)
        )
      end

      def summary(notice)
        summary_metadata(notice).merge(
          message: notice.message.to_s.truncate(MAX_STRING_LENGTH),
          environment: bounded(notice.environment_name),
          app_version: bounded(notice.app_version),
          where: bounded(notice.where),
          host: bounded(notice.host),
          backtrace_id: notice.backtrace_id.to_s
        )
      end

      def metadata(notice)
        {
          id: notice.id.to_s,
          app_id: notice.app_id.to_s,
          err_id: notice.err_id.to_s,
          backtrace_id: notice.backtrace_id.to_s,
          created_at: notice.created_at&.iso8601,
          updated_at: notice.updated_at&.iso8601
        }
      end

      def data(notice)
        notice.attributes.slice(
          "message", "server_environment", "request", "notifier", "user_attributes", "framework", "error_class"
        ).transform_keys(&:to_sym)
      end

      private

      def summary_metadata(notice)
        {
          id: notice.id.to_s,
          created_at: notice.created_at&.iso8601,
          app_id: notice.app_id.to_s,
          err_id: notice.err_id.to_s,
          problem_id: notice.err&.problem_id&.to_s,
          error_class: bounded(notice.error_class),
          framework: bounded(notice.framework)
        }
      end

      def bounded(value)
        value&.to_s&.truncate(MAX_STRING_LENGTH)
      end
    end
  end
end
