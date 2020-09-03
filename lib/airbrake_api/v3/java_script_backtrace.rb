module AirbrakeApi
  module V3
    class JavaScriptBacktrace
      def self.new(*args)
        Errbit::Config.enable_source_maps ? super(*args) : DefaultBacktrace.new(*args)
      end

      def initialize(lines)
        @lines = lines
        @source_map_cache = {}
      end

      def normalized_lines
        lines.map { |backtrace_line| source_map(backtrace_line['file']).original_line(backtrace_line) }
      end

    private

      attr_reader :lines, :source_map_cache

      def source_map(file)
        source_map_cache[file] ||= RemoteJsFile.new(file).source_map
      end
    end
  end
end
