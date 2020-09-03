module AirbrakeApi
  module V3
    class RemoteSourceMap
      def initialize(remote_file)
        @remote_file = remote_file
      end

      def original_line(generated_line)
        SourceMapLine.new(source_map, generated_line).original_line
      end

      def data
        return @data if defined?(@data)

        @data = JSON.parse(RemoteContent.new(remote_file).data)
      rescue RemoteContent::Error
        @data = nil
      end

    private

      attr_reader :remote_file, :downloaded

      def source_map
        return nil if data.nil?
        return @source_map if defined?(@source_map)

        @source_map = SourceMap::Map.from_hash(data)
      rescue JSON::ParserError
        @source_map = nil
      end
    end
  end
end
