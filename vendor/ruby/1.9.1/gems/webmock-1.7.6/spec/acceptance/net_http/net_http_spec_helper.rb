module NetHTTPSpecHelper
  def http_request(method, uri, options = {}, &block)
    begin
      uri = URI.parse(uri)
    rescue
      uri = Addressable::URI.heuristic_parse(uri)
    end
    response = nil
    clazz = Net::HTTP.const_get("#{method.to_s.capitalize}")
    req = clazz.new("#{uri.path}#{uri.query ? '?' : ''}#{uri.query}", nil)
    options[:headers].each do |k,v|
      if v.is_a?(Array)
        v.each_with_index do |v,i|
          i == 0 ? (req[k] = v) : req.add_field(k, v)
        end
      else
        req[k] = v
      end
    end if options[:headers]

    req.basic_auth uri.user, uri.password if uri.user
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == "https"
      http.use_ssl = true
      #1.9.1 has a bug with ssl_timeout
      http.ssl_timeout = 10 unless RUBY_VERSION == "1.9.1"
    end
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.start {|http|
      http.request(req, options[:body], &block)
    }
    headers = {}
    response.each_header {|name, value| headers[name] = value}
    OpenStruct.new({
      :body => response.body,
      :headers => WebMock::Util::Headers.normalize_headers(headers),
      :status => response.code,
      :message => response.message
    })
  end

  def client_timeout_exception_class
    Timeout::Error
  end

  def connection_refused_exception_class
    Errno::ECONNREFUSED
  end

  def http_library
    :net_http
  end
end
