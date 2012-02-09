require "heroku/helpers"
require 'digest/sha2'

module HerokuPostgresql
  class Client
    Version = 10

    include Heroku::Helpers

    def initialize(url)
      @heroku_postgresql_host = ENV["HEROKU_POSTGRESQL_HOST"] || "https://shogun.heroku.com"
      @database_sha = sha(url)
      @heroku_postgresql_resource = RestClient::Resource.new(
        "#{@heroku_postgresql_host}/client/v10/databases",
        :headers =>  { :x_heroku_gem_version  => Heroku::Client.version }
        )
    end

    def ingress
      http_put "#{@database_sha}/ingress"
    end

    def reset
      http_put "#{@database_sha}/reset"
    end

    def get_database
      http_get @database_sha
    end

    def get_wait_status
      http_get "#{@database_sha}/wait_status"
    end

    def unfollow
      http_put "#{@database_sha}/unfollow"
    end

    protected

    def sha(url)
      Digest::SHA2.hexdigest url
    end

    def sym_keys(c)
      if c.is_a?(Array)
        c.map { |e| sym_keys(e) }
      else
        c.inject({}) do |h, (k, v)|
          h[k.to_sym] = v; h
        end
      end
    end

    def checking_client_version
      begin
        yield
      rescue RestClient::BadRequest => e
        if message = json_decode(e.response.to_s)["upgrade_message"]
          abort(message)
        else
          raise e
        end
      end
    end

    def display_heroku_warning(response)
      warning = response.headers[:x_heroku_warning]
      display warning if warning
      response
    end

    def http_get(path)
      checking_client_version do
        retry_on_exception(RestClient::Exception) do
          response = @heroku_postgresql_resource[path].get
          display_heroku_warning response
          sym_keys(json_decode(response.to_s))
        end
      end
    end

    def http_post(path, payload = {})
      checking_client_version do
        response = @heroku_postgresql_resource[path].post(json_encode(payload))
        display_heroku_warning response
        sym_keys(json_decode(response.to_s))
      end
    end

    def http_put(path, payload = {})
      checking_client_version do
        response = @heroku_postgresql_resource[path].put(json_encode(payload))
        display_heroku_warning response
        sym_keys(json_decode(response.to_s))
      end
    end
  end
end
