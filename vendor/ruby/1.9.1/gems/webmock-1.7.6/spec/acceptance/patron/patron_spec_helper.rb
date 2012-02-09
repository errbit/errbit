require 'ostruct'

module PatronSpecHelper
  def http_request(method, uri, options = {}, &block)
    uri = Addressable::URI.heuristic_parse(uri)
    sess = Patron::Session.new
    sess.base_url = "#{uri.omit(:userinfo, :path, :query).normalize.to_s}".gsub(/\/$/,"")
    sess.username = uri.user
    sess.password = uri.password

    sess.connect_timeout = 10
    sess.timeout = 10
    sess.max_redirects = 0
    uri = "#{uri.path}#{uri.query ? '?' : ''}#{uri.query}"
    uri.gsub!(' ','+')
    response = sess.request(method, uri, options[:headers] || {}, {
      :data => options[:body]
    })
    headers = {}
    if response.headers
      response.headers.each do |k,v|
        v = v.join(", ") if v.is_a?(Array)
        headers[k] = v
      end
    end

    status_line_pattern = %r(\AHTTP/(\d+\.\d+)\s+(\d\d\d)\s*([^\r\n]+)?)
    message = response.status_line.match(status_line_pattern)[3] || ""

    OpenStruct.new({
      :body => response.body,
      :headers => WebMock::Util::Headers.normalize_headers(headers),
      :status => response.status.to_s,
      :message => message
    })
  end

  def client_timeout_exception_class
    Patron::TimeoutError
  end

  def connection_refused_exception_class
    Patron::ConnectionFailed
  end

  def http_library
    :patron
  end

end
