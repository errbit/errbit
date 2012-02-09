module HoptoadNotifier
  # Sends out the notice to Hoptoad
  class Sender

    NOTICES_URI = '/notifier_api/v2/notices/'.freeze
    HTTP_ERRORS = [Timeout::Error,
                   Errno::EINVAL,
                   Errno::ECONNRESET,
                   EOFError,
                   Net::HTTPBadResponse,
                   Net::HTTPHeaderSyntaxError,
                   Net::ProtocolError,
                   Errno::ECONNREFUSED].freeze

    def initialize(options = {})
      [:proxy_host, :proxy_port, :proxy_user, :proxy_pass, :protocol,
        :host, :port, :secure, :http_open_timeout, :http_read_timeout].each do |option|
        instance_variable_set("@#{option}", options[option])
      end
    end

    # Sends the notice data off to Hoptoad for processing.
    #
    # @param [String] data The XML notice to be sent off
    def send_to_hoptoad(data)
      logger.debug { "Sending request to #{url.to_s}:\n#{data}" } if logger

      http =
        Net::HTTP::Proxy(proxy_host, proxy_port, proxy_user, proxy_pass).
        new(url.host, url.port)

      http.read_timeout = http_read_timeout
      http.open_timeout = http_open_timeout
      http.use_ssl      = secure

      response = begin
                   http.post(url.path, data, HEADERS)
                 rescue *HTTP_ERRORS => e
                   log :error, "Timeout while contacting the Hoptoad server."
                   nil
                 end

      case response
      when Net::HTTPSuccess then
        log :info, "Success: #{response.class}", response
      else
        log :error, "Failure: #{response.class}", response
      end

      if response && response.respond_to?(:body)
        error_id = response.body.match(%r{<error-id[^>]*>(.*?)</error-id>})
        error_id[1] if error_id
      end
    end

    private

    attr_reader :proxy_host, :proxy_port, :proxy_user, :proxy_pass, :protocol,
      :host, :port, :secure, :http_open_timeout, :http_read_timeout

    def url
      URI.parse("#{protocol}://#{host}:#{port}").merge(NOTICES_URI)
    end

    def log(level, message, response = nil)
      logger.send level, LOG_PREFIX + message if logger
      HoptoadNotifier.report_environment_info
      HoptoadNotifier.report_response_body(response.body) if response && response.respond_to?(:body)
    end

    def logger
      HoptoadNotifier.logger
    end

  end
end
