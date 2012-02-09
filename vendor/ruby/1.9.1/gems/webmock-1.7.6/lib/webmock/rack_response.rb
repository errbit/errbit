module WebMock
  class RackResponse < Response
    def initialize(app)
      @app = app
    end

    def evaluate(request)
      env = build_rack_env(request)

      status, headers, response = @app.call(env)

      Response.new(
        :body => response.join,
        :headers => headers,
        :status => status
      )
    end

    def build_rack_env(request)
      uri = request.uri
      headers = request.headers || {}
      body = request.body || ''

      env = {
        # CGI variables specified by Rack
        'REQUEST_METHOD' => request.method.to_s.upcase,
        'CONTENT_TYPE'   => headers.delete('Content-Type'),
        'CONTENT_LENGTH' => body.size,
        'PATH_INFO'      => uri.path,
        'QUERY_STRING'   => uri.query || '',
        'SERVER_NAME'    => uri.host
      }

      # Rack-specific variables
      env['rack.input']      = StringIO.new(body)
      env['rack.version']    = Rack::VERSION
      env['rack.url_scheme'] = uri.scheme
      env['rack.run_once']   = true
      env['rack.session']    = session

      headers.each do |k, v|
        env["HTTP_#{k.tr('-','_').upcase}"] = v
      end

      env
    end

    def session
      @session ||= {}
    end
  end
end
