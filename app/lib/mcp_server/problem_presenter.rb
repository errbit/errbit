# frozen_string_literal: true

module McpServer
  class ProblemPresenter
    MAX_STRING_LENGTH = 500

    class << self
      def summary(problem)
        safe_attributes(problem).merge(metadata(problem))
      end

      def detail(problem)
        summary(problem).merge(issue_link: bounded(problem.issue_link))
      end

      private

      def string_metadata(problem)
        {
          app_name: bounded(problem.app_name),
          message: problem.message.to_s.truncate(MAX_STRING_LENGTH),
          url: bounded(problem.url)
        }
      end

      def safe_attributes(problem)
        attributes = problem.attributes.slice(
          "environment", "error_class", "where", "resolved", "notices_count", "comments_count"
        ).transform_keys(&:to_sym)
        attributes.merge(
          environment: bounded(attributes[:environment]),
          error_class: bounded(attributes[:error_class]),
          where: bounded(attributes[:where])
        )
      end

      def metadata(problem)
        {
          id: problem.id.to_s,
          app_id: problem.app_id.to_s,
          first_notice_at: problem.first_notice_at&.iso8601,
          last_notice_at: problem.last_notice_at&.iso8601,
          resolved_at: problem.resolved_at&.iso8601
        }.merge(string_metadata(problem))
      end

      def bounded(value)
        value&.to_s&.truncate(MAX_STRING_LENGTH)
      end
    end
  end
end
