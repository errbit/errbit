require 'typhoeus'

module Fogbugz
  module Adapter
    module HTTP
      class Typhoeuser
        attr_accessor :uri, :requester

        def initialize(options = {})
          @uri = options[:uri]
          @requester = Typhoeus::Request
        end

        def request(action, options)
          params = {:cmd => action}.merge(options[:params])
          query = @requester.get("#{uri}/api.asp",
                                 :params => params)
          query.body
        end
      end
    end
  end
end
