module Octokit
  class Client
    module PubSubHubbub
      # Subscribe to a pubsub topic
      #
      # @param topic [String] A recoginized and supported pubsub topic
      # @param callback [String] A callback url to be posted to when the topic event is fired
      # @return [boolean] true if the subscribe was successful, otherwise an error is raised
      # @example Subscribe to push events from one of your repositories, having an email sent when fired
      #   client = Octokit::Client.new(:oauth_token = "token")
      #   client.subscribe("https://github.com/joshk/devise_imapable/events/push", "github://Email?address=josh.kalderimis@gmail.com")
      def subscribe(topic, callback)
        options = {
          :"hub.mode" => "subscribe",
          :"hub.topic" => topic,
          :"hub.callback" => callback,
        }
        post("/hub", options, 3, true, true, true)
        true
      end

      # Unsubscribe from a pubsub topic
      #
      # @param topic [String] A recoginized pubsub topic
      # @param callback [String] A callback url to be unsubscribed from
      # @return [boolean] true if the unsubscribe was successful, otherwise an error is raised
      # @example Unsubscribe to push events from one of your repositories, no longer having an email sent when fired
      #   client = Octokit::Client.new(:oauth_token = "token")
      #   client.unsubscribe("https://github.com/joshk/devise_imapable/events/push", "github://Email?address=josh.kalderimis@gmail.com")
      def unsubscribe(topic, callback)
        options = {
          :"hub.mode" => "unsubscribe",
          :"hub.topic" => topic,
          :"hub.callback" => callback,
        }
        post("/hub", options, 3, true, true, true)
        true
      end
    end
  end
end
