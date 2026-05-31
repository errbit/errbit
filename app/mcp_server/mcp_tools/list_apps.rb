# frozen_string_literal: true

module McpTools
  class ListApps < MCP::Tool
    tool_name "errbit_list_apps"
    description "List apps in Errbit"

    def self.call
      apps = App.all

      apps_formatted = apps.map(&:to_md_short)

      MCP::Tool::Response.new([{type: "text", text: apps_formatted.join("\n---\n")}])
    end
  end
end
