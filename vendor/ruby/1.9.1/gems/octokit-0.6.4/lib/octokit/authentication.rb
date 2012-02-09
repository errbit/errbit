module Octokit
  module Authentication
    def authentication
      if login && token
        {:login => "#{login}/token", :password => token}
      elsif login && password
        {:login => login, :password => password}
      else
        {}
      end
    end

    def authenticated?
      !authentication.empty?
    end

    def oauthed?
      !oauth_token.nil?
    end
  end
end
