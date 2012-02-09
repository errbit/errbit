module Rack
  class SslEnforcer

    # Warning: If you set the option force_secure_cookies to false, make sure that your cookies
    #  are encoded and that you understand the consequences (see documentation)
    def initialize(app, options={})
      default_options = {
        :redirect_to => nil,
        :only => nil,
        :only_hosts => nil,
        :except => nil,
        :except_hosts => nil,
        :strict => false,
        :mixed => false,
        :hsts => nil,
        :http_port => nil,
        :https_port => nil,
        :force_secure_cookies => true
      }
      @app, @options = app, default_options.merge(options)
    end

    def call(env)
      @req = Rack::Request.new(env)
      if enforce_ssl?(@req)
        scheme = 'https' unless ssl_request?(env)
      elsif ssl_request?(env) && enforcement_non_ssl?(env)
        scheme = 'http'
      end

      if scheme
        location = replace_scheme(@req, scheme)
        body     = "<html><body>You are being <a href=\"#{location}\">redirected</a>.</body></html>"
        [301, { 'Content-Type' => 'text/html', 'Location' => location }, [body]]
      elsif ssl_request?(env)
        status, headers, body = @app.call(env)
        flag_cookies_as_secure!(headers) if @options[:force_secure_cookies]
        set_hsts_headers!(headers) if @options[:hsts] && !@options[:strict]
        [status, headers, body]
      else
        @app.call(env)
      end
    end

  private

    def enforcement_non_ssl?(env)
      true if @options[:strict] || @options[:mixed] && !(env['REQUEST_METHOD'] == 'PUT' || env['REQUEST_METHOD'] == 'POST')
    end

    def ssl_request?(env)
      scheme(env) == 'https'
    end

    # Fixed in rack >= 1.3
    def scheme(env)
      if env['HTTPS'] == 'on'
        'https'
      elsif env['HTTP_X_FORWARDED_PROTO']
        env['HTTP_X_FORWARDED_PROTO'].split(',')[0]
      else
        env['rack.url_scheme']
      end
    end

    def matches?(key, pattern, req)
      if pattern.is_a?(Regexp)
        case key
        when :only
          req.path =~ pattern
        when :except
          req.path !~ pattern
        when :only_hosts
          req.host =~ pattern
        when :except_hosts
          req.host !~ pattern
        end
      else
        case key
        when :only
          req.path[0,pattern.length] == pattern
        when :except
          req.path[0,pattern.length] != pattern
        when :only_hosts
          req.host == pattern
        when :except_hosts
          req.host != pattern
        end
      end
    end

    def enforce_ssl_for?(keys, req)
      if keys.any? { |option| @options[option] }
        keys.any? do |key|
          rules = [@options[key]].flatten.compact
          unless rules.empty?
            rules.send(key == :except_hosts || key == :except ? "all?" : "any?") do |pattern|
              matches?(key, pattern, req)
            end
          end
        end
      else
        false
      end
    end

    def enforce_ssl?(req)
      path_keys = [:only, :except]
      hosts_keys = [:only_hosts, :except_hosts]
      if hosts_keys.any? { |option| @options[option] }
        if enforce_ssl_for?(hosts_keys, req)
          if path_keys.any? { |option| @options[option] }
            enforce_ssl_for?(path_keys, req)
          else
            true
          end
        else
          false
        end
      elsif path_keys.any? { |option| @options[option] }
        enforce_ssl_for?(path_keys, req)
      else
        true
      end
    end

    def replace_scheme(req, scheme)
      if @options[:redirect_to]
        uri = URI.split(@options[:redirect_to])
        uri = uri[2] || uri[5]
      else
        uri = nil
      end
      host = uri || req.host
      port = port_for(scheme).to_s

      URI.parse("#{scheme}://#{host}:#{port}#{req.fullpath}").to_s
    end

    def port_for(scheme)
      if scheme == 'https'
        @options[:https_port] || 443
      else
        @options[:http_port] || 80
      end
    end

    # see http://en.wikipedia.org/wiki/HTTP_cookie#Cookie_theft_and_session_hijacking
    def flag_cookies_as_secure!(headers)
      if cookies = headers['Set-Cookie']
        # Support Rails 2.3 / Rack 1.1 arrays as headers
        unless cookies.is_a?(Array)
          cookies = cookies.split("\n")
        end

        headers['Set-Cookie'] = cookies.map do |cookie|
          cookie !~ / secure;/ ? "#{cookie}; secure" : cookie
        end.join("\n")
      end
    end

    # see http://en.wikipedia.org/wiki/Strict_Transport_Security
    def set_hsts_headers!(headers)
      opts = { :expires => 31536000, :subdomains => true }
      opts.merge!(@options[:hsts]) if @options[:hsts].is_a? Hash
      value  = "max-age=#{opts[:expires]}"
      value += "; includeSubDomains" if opts[:subdomains]
      headers.merge!({ 'Strict-Transport-Security' => value })
    end

  end
end
