module PivotalTracker
  class Client

    class NoToken < StandardError; end

    class << self
      attr_writer :use_ssl, :token

      def use_ssl
        @use_ssl || false
      end

      def token(username, password, method='post')
        return @token if @token
        response = if method == 'post'
          RestClient.post 'https://www.pivotaltracker.com/services/v3/tokens/active', :username => username, :password => password
        else
          RestClient.get "https://#{username}:#{password}@www.pivotaltracker.com/services/v3/tokens/active"
        end
        @token= Nokogiri::XML(response.body).search('guid').inner_html
      end

      # this is your connection for the entire module
      def connection(options={})
        raise NoToken if @token.to_s.empty?

        @connections ||= {}

        @connections[@token] ||= RestClient::Resource.new("#{protocol}://www.pivotaltracker.com/services/v3", :headers => {'X-TrackerToken' => @token, 'Content-Type' => 'application/xml'})
      end

      protected

        def protocol
          use_ssl ? 'https' : 'http'
        end

    end

  end
end
