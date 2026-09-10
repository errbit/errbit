# frozen_string_literal: true

module McpServer
  module Tools
    class ListProblems < MCP::Tool
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      tool_name "errbit_list_problems"
      description "List Errbit problems, ordered by most recent notice."
      annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false
      input_schema(
        properties: {
          app_id: {type: "string", minLength: 1, maxLength: 100},
          app_name: {type: "string", minLength: 1, maxLength: 200},
          environment: {type: "string", minLength: 1, maxLength: 100},
          resolved: {type: "boolean"},
          search: {type: "string", minLength: 1, maxLength: 200},
          page: {type: "integer", minimum: 1},
          per_page: {type: "integer", minimum: 1, maximum: MAX_PER_PAGE}
        }
      )

      class << self
        def call(**arguments)
          page = arguments.fetch(:page, 1)
          per_page = arguments.fetch(:per_page, DEFAULT_PER_PAGE)
          problems = filtered_problems(arguments)
          problems = problems.order_by(last_notice_at: :desc, _id: :desc).page(page).per(per_page)

          ToolResponse.success(result(problems, page, per_page))
        end

        private

        def result(problems, page, per_page)
          {
            problems: problems.map { |problem| ProblemPresenter.summary(problem) },
            page: page,
            per_page: per_page,
            total_pages: problems.total_pages,
            total_count: problems.total_count
          }
        end

        def filtered_problems(arguments)
          problems = Problem.all
          filters = arguments.slice(:app_id, :app_name, :environment).compact
          problems = problems.where(filters) if filters.any?
          problems = arguments[:resolved] ? problems.resolved : problems.unresolved unless arguments[:resolved].nil?
          problems = problems.search(arguments[:search]) if arguments[:search]
          problems
        end
      end
    end
  end
end
