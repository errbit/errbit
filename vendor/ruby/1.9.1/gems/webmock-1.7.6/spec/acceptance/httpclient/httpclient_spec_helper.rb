module HTTPClientSpecHelper
  class << self
    attr_accessor :async_mode
  end

  def http_request(method, uri, options = {}, &block)
    uri = Addressable::URI.heuristic_parse(uri)
    c = HTTPClient.new
    c.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    c.set_basic_auth(nil, uri.user, uri.password) if uri.user
    params = [method, "#{uri.omit(:userinfo, :query).normalize.to_s}",
      uri.query_values, options[:body], options[:headers] || {}]
    if HTTPClientSpecHelper.async_mode
      connection = c.request_async(*params)
      connection.join
      response = connection.pop
    else
      response = c.request(*params, &block)
    end
    headers = response.header.all.inject({}) do |headers, header|
      if !headers.has_key?(header[0])
        headers[header[0]] = header[1]
      else
        headers[header[0]] = [headers[header[0]], header[1]].join(', ')
      end
      headers
    end
    OpenStruct.new({
      :body => HTTPClientSpecHelper.async_mode ? response.content.read : response.content,
      :headers => headers,
      :status => response.code.to_s,
      :message => response.reason
    })
  end

  def client_timeout_exception_class
    HTTPClient::TimeoutError
  end

  def connection_refused_exception_class
    Errno::ECONNREFUSED
  end

  def http_library
    :httpclient
  end

end
