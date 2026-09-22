# frozen_string_literal: true

module McpServer
  module Tools
    class ListApps < MCP::Tool
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      tool_name "errbit_list_apps"
      description "List Errbit applications, ordered by name."
      annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false
      input_schema(
        properties: {
          search: {type: "string", minLength: 1, maxLength: 200},
          page: {type: "integer", minimum: 1},
          per_page: {type: "integer", minimum: 1, maximum: MAX_PER_PAGE}
        }
      )

      class << self
        def call(search: nil, page: 1, per_page: DEFAULT_PER_PAGE, **)
          apps = filtered_apps(search).order_by(name: :asc, _id: :asc).page(page).per(per_page)
          ToolResponse.success({
            apps: apps.map { |app| AppPresenter.summary(app) },
            page: page,
            per_page: per_page,
            total_pages: apps.total_pages,
            total_count: apps.total_count
          })
        end

        private

        def filtered_apps(search)
          apps = App.all
          apps = apps.where(name: /#{Regexp.escape(search)}/i) if search
          apps
        end
      end
    end
  end
end
