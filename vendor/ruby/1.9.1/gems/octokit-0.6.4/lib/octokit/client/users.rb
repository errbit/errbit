module Octokit
  class Client
    module Users
      EMAIL_RE = /[\w.!#\$%+-]+@[\w-]+(?:\.[\w-]+)+/
      def search_users(search, options={})
        if search.match(EMAIL_RE)
          get("/api/v2/json/user/email/#{search}", options)['user']
        else
          get("/api/v2/json/user/search/#{search}", options)['users']
        end
      end

      # Get a single user
      #
      # @param user [String] A GitHub user name.
      # @return [Hashie::Mash]
      # @example
      #   Octokit.user("sferik")
      def user(user=nil)
        if user
          get("/users/#{user}", {}, 3)
        else
          get("/user", {}, 3)
        end
      end

      # Update the authenticated user
      #
      # @param options [Hash] A customizable set of options.
      # @option options [String] :name
      # @option options [String] :email Publically visible email address.
      # @option options [String] :blog
      # @option options [String] :company
      # @option options [String] :location
      # @option options [Boolean] :hireable
      # @option options [String] :bio
      # @return [Hashie::Mash]
      # @example
      #   Octokit.user(:name => "Erik Michaels-Ober", :email => "sferik@gmail.com", :company => "Code for America", :location => "San Francisco", :hireable => false)
      def update_user(options)
        patch("/user", options, 3)
      end

      def followers(user=login, options={})
        get("/api/v2/json/user/show/#{user}/followers", options)['users']
      end

      def following(user=login, options={})
        get("/api/v2/json/user/show/#{user}/following", options)['users']
      end

      def follows?(*args)
        target = args.pop
        user = args.first
        user ||= login
        return if user.nil?
        following(user).include?(target)
      end

      def follow(user, options={})
        post("/api/v2/json/user/follow/#{user}", options)['users']
      end

      def unfollow(user, options={})
        post("/api/v2/json/user/unfollow/#{user}", options)['users']
      end

      def watched(user=login, options={})
        get("/api/v2/json/repos/watched/#{user}", options)['repositories']
      end

      def keys(options={})
        get("/api/v2/json/user/keys", options)['public_keys']
      end

      def add_key(title, key, options={})
        post("/api/v2/json/user/key/add", options.merge({:title => title, :key => key}))['public_keys']
      end

      def remove_key(id, options={})
        post("/api/v2/json/user/key/remove", options.merge({:id => id}))['public_keys']
      end

      def emails(options={})
        get("/api/v2/json/user/emails", options)['emails']
      end

      def add_email(email, options={})
        post("/api/v2/json/user/email/add", options.merge({:email => email}))['emails']
      end

      def remove_email(email, options={})
        post("/api/v2/json/user/email/remove", options.merge({:email => email}))['emails']
      end
    end
  end
end
