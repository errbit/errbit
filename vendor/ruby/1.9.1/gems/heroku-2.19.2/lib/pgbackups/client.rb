require "heroku/helpers"

module PGBackups
  class Client
    include Heroku::Helpers

    def initialize(uri)
      @uri = URI.parse(uri)
    end

    def authenticated_resource(path)
      host = "#{@uri.scheme}://#{@uri.host}"
      host += ":#{@uri.port}" if @uri.port
      RestClient::Resource.new("#{host}#{path}",
        :user     => @uri.user,
        :password => @uri.password,
        :headers  => {:x_heroku_gem_version => Heroku::Client.version}
      )
    end

    def create_transfer(from_url, from_name, to_url, to_name, opts={})
      # opts[:expire] => true will delete the oldest backup if at the plan limit
      resource = authenticated_resource("/client/transfers")
      params = {:from_url => from_url, :from_name => from_name, :to_url => to_url, :to_name => to_name}.merge opts
      json_decode post(resource, params).body
    end

    def get_transfers
      resource = authenticated_resource("/client/transfers")
      json_decode get(resource).body
    end

    def get_transfer(id)
      resource = authenticated_resource("/client/transfers/#{id}")
      json_decode get(resource).body
    end

    def get_backups(opts={})
      resource = authenticated_resource("/client/backups")
      json_decode get(resource).body
    end

    def get_backup(name, opts={})
      name = URI.escape(name)
      resource = authenticated_resource("/client/backups/#{name}")
      json_decode get(resource).body
    end

    def get_latest_backup
      resource = authenticated_resource("/client/latest_backup")
      json_decode get(resource).body
    end

    def delete_backup(name)
      name = URI.escape(name)
      begin
        resource = authenticated_resource("/client/backups/#{name}")
        delete(resource).body
        true
      rescue RestClient::ResourceNotFound => e
        false
      end
    end

    private

    def get(resource)
      check_errors do
        response = resource.get
        display_heroku_warning response
        response
      end
    end

    def post(resource, params)
      check_errors do
        response = resource.post(params)
        display_heroku_warning response
        response
      end
    end

    def delete(resource)
      check_errors do
        response = resource.delete
        display_heroku_warning response
        response
      end
    end

    def check_errors
      yield
    rescue RestClient::Unauthorized
      error "Invalid PGBACKUPS_URL"
    end

    def display_heroku_warning(response)
      warning = response.headers[:x_heroku_warning]
      display warning if warning
      response
    end

  end
end
