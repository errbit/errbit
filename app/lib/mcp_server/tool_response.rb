# frozen_string_literal: true

module McpServer
  class ToolResponse
    class << self
      def success(result)
        response(result)
      end

      def error(result)
        response(result, error: true)
      end

      def response(result, error: false)
        MCP::Tool::Response.new(
          [{type: "text", text: result.to_json}],
          structured_content: result,
          error: error
        )
      end
      private :response
    end
  end
end
