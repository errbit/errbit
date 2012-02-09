require 'multi_json'

module Octokit
  module Request
    def delete(path, options={}, version=api_version, authenticate=true, raw=false, force_urlencoded=false)
      request(:delete, path, options, version, authenticate, raw, force_urlencoded)
    end

    def get(path, options={}, version=api_version, authenticate=true, raw=false, force_urlencoded=false)
      request(:get, path, options, version, authenticate, raw, force_urlencoded)
    end

    def patch(path, options={}, version=api_version, authenticate=true, raw=false, force_urlencoded=false)
      request(:patch, path, options, version, authenticate, raw, force_urlencoded)
    end

    def post(path, options={}, version=api_version, authenticate=true, raw=false, force_urlencoded=false)
      request(:post, path, options, version, authenticate, raw, force_urlencoded)
    end

    def put(path, options={}, version=api_version, authenticate=true, raw=false, force_urlencoded=false)
      request(:put, path, options, version, authenticate, raw, force_urlencoded)
    end

    private

    def request(method, path, options, version, authenticate, raw, force_urlencoded)
      response = connection(authenticate, raw, version, force_urlencoded).send(method) do |request|
        case method
        when :delete, :get
          request.url(path, options)
        when :patch, :post, :put
          request.path = path
          if 3 == version && !force_urlencoded
            request.body = MultiJson.encode(options) unless options.empty?
          else
            request.body = options unless options.empty?
          end
        end
      end
      raw ? response : response.body
    end
  end
end
