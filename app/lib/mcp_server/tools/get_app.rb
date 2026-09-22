# frozen_string_literal: true

module McpServer
  module Tools
    class GetApp < MCP::Tool
      tool_name "errbit_get_app"
      description "Get safe details for an Errbit application by ID."
      annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false
      input_schema(
        properties: {
          id: {type: "string", minLength: 1}
        },
        required: ["id"]
      )

      class << self
        def call(id:, **)
          ToolResponse.success({app: AppPresenter.detail(App.find(id))})
        rescue Mongoid::Errors::DocumentNotFound
          ToolResponse.error({error: "app_not_found", id: id})
        end
      end
    end
  end
end
