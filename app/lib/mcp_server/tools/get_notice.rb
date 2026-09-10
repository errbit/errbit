# frozen_string_literal: true

module McpServer
  module Tools
    class GetNotice < MCP::Tool
      MAX_PAYLOAD_BYTES = 1_000_000

      tool_name "errbit_get_notice"
      description "Get one persisted Errbit notice by ID."
      annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false
      input_schema(
        properties: {
          id: {type: "string", minLength: 1, maxLength: 100}
        },
        required: ["id"]
      )

      class << self
        def call(id:, **)
          notice = Notice.find(id)
          payload = payload(notice)
          return ToolResponse.error(error: "notice_too_large", max_bytes: MAX_PAYLOAD_BYTES) if payload.to_json.bytesize > MAX_PAYLOAD_BYTES

          ToolResponse.success(notice: payload)
        rescue Mongoid::Errors::DocumentNotFound
          ToolResponse.error(error: "notice_not_found", id: id)
        end

        private

        def payload(notice)
          problem = notice.problem
          NoticePresenter.full(notice).merge(
            problem_id: problem.id.to_s,
            problem_url: problem.url,
            problem: ProblemPresenter.summary(problem),
            app: AppPresenter.summary(problem.app)
          )
        end
      end
    end
  end
end
