# frozen_string_literal: true

module McpServer
  module Tools
    class GetAirbrakeSetupGuidance < MCP::Tool
      FRAMEWORKS = ["ruby", "node", "python", "go"].freeze

      tool_name "errbit_get_airbrake_setup_guidance"
      description "Get safe Airbrake-compatible Errbit setup guidance and app metadata without credentials."
      annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false
      input_schema(
        properties: {
          app_id: {type: "string", minLength: 1, maxLength: 100},
          framework: {type: "string", minLength: 1, maxLength: 50}
        }
      )

      class << self
        def call(app_id: nil, framework: nil, **)
          return ToolResponse.error({error: "unsupported_framework", framework: framework}) if framework && FRAMEWORKS.exclude?(framework)

          app = App.find(app_id) if app_id
          ToolResponse.success(guidance(app, framework))
        rescue Mongoid::Errors::DocumentNotFound
          ToolResponse.error({error: "app_not_found", app_id: app_id})
        end

        private

        def guidance(app, framework)
          {
            endpoint: "https://#{Errbit::Config.host}/api/v3/projects/{project_id}/notices",
            app: app && {id: app.id.to_s, name: app.name},
            project_id: 1,
            project_key: "<ERRBIT_APP_API_KEY>",
            api_key_instructions: "Copy the app ingestion key from the Errbit app settings. MCP never returns app API keys.",
            snippets: snippets(framework)
          }
        end

        def snippets(framework)
          framework ? {framework => template_for(framework)} : FRAMEWORKS.index_with { |name| template_for(name) }
        end

        def template_for(framework)
          send(:"#{framework}_template")
        end

        def ruby_template
          <<~RUBY
            Airbrake.configure do |config|
              config.error_host = "https://#{Errbit::Config.host}"
              config.project_id = 1
              config.project_key = "<ERRBIT_APP_API_KEY>"
              config.environment = Rails.env
              config.job_stats = false
              config.query_stats = false
              config.performance_stats = false
              config.remote_config = false
            end
          RUBY
        end

        def node_template
          "new Notifier({host: \"https://#{Errbit::Config.host}\", projectId: 1, projectKey: \"<ERRBIT_APP_API_KEY>\", environment: process.env.NODE_ENV});"
        end

        def python_template
          "pybrake.Notifier(project_id=1, project_key=\"<ERRBIT_APP_API_KEY>\", host=\"https://#{Errbit::Config.host}\", environment=\"production\")"
        end

        def go_template
          "gobrake.NewNotifierWithOptions(&gobrake.NotifierOptions{ProjectId: 1, ProjectKey: \"<ERRBIT_APP_API_KEY>\", Host: \"https://#{Errbit::Config.host}\", Environment: \"production\"})"
        end
      end
    end
  end
end
