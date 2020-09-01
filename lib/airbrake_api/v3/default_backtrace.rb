module AirbrakeApi
  module V3
    class DefaultBacktrace
      def initialize(lines)
        @lines = lines
      end

      def normalized_lines
        lines.map do |backtrace_line|
          {
            method: backtrace_line['function'],
            file: backtrace_line['file'],
            number: backtrace_line['line'],
            column: backtrace_line['column']
          }
        end
      end

      private

      attr_reader :lines
    end
  end
end
