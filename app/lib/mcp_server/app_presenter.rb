# frozen_string_literal: true

module McpServer
  class AppPresenter
    class << self
      def summary(app)
        {
          id: app.id.to_s,
          name: app.name,
          created_at: app.created_at.iso8601,
          updated_at: app.updated_at.iso8601
        }
      end

      def detail(app)
        summary(app).merge(
          problem_count: app.problem_count,
          unresolved_problem_count: app.unresolved_count
        )
      end
    end
  end
end
