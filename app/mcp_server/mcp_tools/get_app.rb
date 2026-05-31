# frozen_string_literal: true

module McpTools
  class GetApp < MCP::Tool
    tool_name "errbit_get_app"
    description "Get details of an app in Errbit by its ID"
    input_schema(
      properties: {
        id: {
          type: "string",
          description: "Errbit App ID"
        }
      },
      required: ["id"]
    )

    def self.call(id:)
      app = App.find(id)

      output =
        <<~APP
          ID: #{app.id}
          Name: #{app.name}
          Created At: #{app.created_at}
          Updated At: #{app.updated_at}
        APP

      MCP::Tool::Response.new([{ type: "text", text: output }])
    rescue Mongoid::Errors::DocumentNotFound
      MCP::Tool::Response.new([{ type: "text", text: "App not found" }])
    end
  end
end
