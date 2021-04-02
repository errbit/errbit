module AirbrakeApi
  module V3
    class RemoteContent
      class Error < StandardError; end

      def initialize(url)
        @url = url
      end

      def data
        file = Down.open(url)
        result = file.read(Errbit::Config.remote_content_limit)

        raise Error unless file.eof?

        result
      rescue Down::Error
        raise Error
      ensure
        file.close if file
      end

    private

      attr_reader :url
    end
  end
end
