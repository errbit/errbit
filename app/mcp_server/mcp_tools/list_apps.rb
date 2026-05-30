# frozen_string_literal: true

module McpTools
  class ListApps < MCP::Tool
    tool_name "errbit_list_apps"
    description "List apps in Errbit"

    def self.call
      apps = App.all

      apps_formatted = apps.map {|app| format_app(app)}

      MCP::Tool::Response.new([{type: "text", text: apps_formatted.join("\n---\n") }])
    end

    def self.format_app(app)
      <<~APP
        ID: #{app.id}
        Name: #{app.name}
      APP
    end
  end
end
