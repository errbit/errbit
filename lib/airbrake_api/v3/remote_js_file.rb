module AirbrakeApi
  module V3
    class RemoteJsFile
      class FileLimitError < StandardError; end

      SOURCE_MAP_COMMENT_IDENTIFIER = '//# sourceMappingURL='

      def initialize(remote_file_url)
        @remote_file_url = remote_file_url
      end

      def source_map
        cached_source_map = fetch_cached_source_map
        return cached_source_map if cached_source_map

        source_map_url = parse_source_map_url

        if source_map_url
          map = RemoteSourceMap.new(source_map_url)
          CachedSourceMap.create(js_file_url: remote_file_url, data: map.data) if map.data
          return map
        end

        DummySourceMap.new
      end

      private

      attr_reader :remote_file_url, :downloaded

      def parse_source_map_url
        js_source = RemoteContent.new(remote_file_url).data

        last_js_line = StringIO.new(js_source).readlines.last
        return unless last_js_line&.include?(SOURCE_MAP_COMMENT_IDENTIFIER)

        source_map_name = last_js_line.sub(SOURCE_MAP_COMMENT_IDENTIFIER, '')

        uri = URI(remote_file_url)

        return source_map_name if URI(source_map_name).scheme

        URI::Generic.build(scheme: uri.scheme,
                           host: uri.host,
                           port: uri.port,
                           path: (uri.path.split('/')[0..-2] + [source_map_name]).join('/')).to_s
      rescue RemoteContent::Error
        # noop
      end

      def fetch_cached_source_map
        CachedSourceMap.find_by(js_file_url: remote_file_url)
      rescue Mongoid::Errors::DocumentNotFound
        nil
      end
    end
  end
end
