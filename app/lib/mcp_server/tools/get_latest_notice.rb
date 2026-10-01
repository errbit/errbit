# frozen_string_literal: true

module McpServer
  module Tools
    class GetLatestNotice < MCP::Tool
      MAX_PAYLOAD_BYTES = 1_000_000

      tool_name "errbit_get_latest_notice"
      description "Get the latest persisted notice for an Errbit problem."
      annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false
      input_schema(
        properties: {
          problem_id: {type: "string", minLength: 1, maxLength: 100}
        },
        required: ["problem_id"]
      )

      class << self
        def call(problem_id:, **)
          problem = Problem.find(problem_id)
          notice = latest_notice(problem)
          return ToolResponse.error(error: "notice_not_found", problem_id: problem_id) unless notice

          payload = payload(problem, notice)
          return ToolResponse.error(error: "notice_too_large", max_bytes: MAX_PAYLOAD_BYTES) if payload.to_json.bytesize > MAX_PAYLOAD_BYTES

          ToolResponse.success(notice: payload)
        rescue Mongoid::Errors::DocumentNotFound
          ToolResponse.error(error: "problem_not_found", problem_id: problem_id)
        end

        private

        def latest_notice(problem)
          Notice.for_errs(problem.errs).reverse_ordered.first
        end

        def payload(problem, notice)
          NoticePresenter.full(notice).merge(problem_id: problem.id.to_s, problem_url: problem.url)
        end
      end
    end
  end
end
