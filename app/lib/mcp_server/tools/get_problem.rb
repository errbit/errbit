# frozen_string_literal: true

module McpServer
  module Tools
    class GetProblem < MCP::Tool
      tool_name "errbit_get_problem"
      description "Get safe details for an Errbit problem by ID."
      annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false
      input_schema(
        properties: {
          id: {type: "string", minLength: 1, maxLength: 100}
        },
        required: ["id"]
      )

      class << self
        def call(id:, **)
          ToolResponse.success(problem: ProblemPresenter.detail(Problem.find(id)))
        rescue Mongoid::Errors::DocumentNotFound
          ToolResponse.error(error: "problem_not_found", id: id)
        end
      end
    end
  end
end
