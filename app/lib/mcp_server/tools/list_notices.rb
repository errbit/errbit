# frozen_string_literal: true

module McpServer
  module Tools
    class ListNotices < MCP::Tool
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      tool_name "errbit_list_notices"
      description "List notice summaries for an Errbit problem or filtered app set, newest first."
      annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false
      input_schema(
        properties: {
          problem_id: {type: "string", minLength: 1, maxLength: 100},
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
        def call(page: 1, per_page: DEFAULT_PER_PAGE, **arguments)
          return ToolResponse.error(error: "invalid_filters") unless filter_present?(arguments)

          notices = filtered_notices(arguments)
          notices = notices.where("$or" => [{message: /#{Regexp.escape(arguments[:search])}/i}, {error_class: /#{Regexp.escape(arguments[:search])}/i}]) if arguments[:search]
          notices = notices.order_by(created_at: :desc, _id: :desc).page(page).per(per_page)

          ToolResponse.success(result(notices, page, per_page))
        rescue Mongoid::Errors::DocumentNotFound
          ToolResponse.error(error: "problem_not_found", problem_id: arguments[:problem_id])
        end

        private

        def filter_present?(arguments)
          arguments.values_at(:problem_id, :app_id, :app_name, :environment, :search).any?(&:present?) || !arguments[:resolved].nil?
        end

        def filtered_notices(arguments)
          err_ids = Err.where(:problem_id.in => filtered_problems(arguments).pluck(:id)).pluck(:id)
          Notice.where(:err_id.in => err_ids)
        end

        def filtered_problems(arguments)
          problems = Problem.all
          problems = Problem.where(_id: Problem.find(arguments[:problem_id]).id) if arguments[:problem_id]
          apply_problem_filters(problems, arguments)
        end

        def apply_problem_filters(problems, arguments)
          problems = problems.where(app_id: arguments[:app_id]) if arguments[:app_id]
          problems = problems.where(app_name: arguments[:app_name]) if arguments[:app_name]
          problems = problems.where(environment: arguments[:environment]) if arguments[:environment]
          problems = arguments[:resolved] ? problems.resolved : problems.unresolved unless arguments[:resolved].nil?
          problems
        end

        def result(notices, page, per_page)
          {
            notices: notices.map { |notice| NoticePresenter.summary(notice) },
            page: page,
            per_page: per_page,
            total_pages: notices.total_pages,
            total_count: notices.total_count
          }
        end
      end
    end
  end
end
