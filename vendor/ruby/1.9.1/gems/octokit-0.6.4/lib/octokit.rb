require 'octokit/configuration'
require 'octokit/client'
require 'octokit/error'

module Octokit
  extend Configuration
  class << self
    # Alias for Octokit::Client.new
    #
    # @return [Octokit::Client]
    def new(options={})
      Octokit::Client.new(options)
    end

    # Delegate to Octokit::Client.new
    def method_missing(method, *args, &block)
      return super unless new.respond_to?(method)
      new.send(method, *args, &block)
    end

    def respond_to?(method, include_private=false)
      new.respond_to?(method, include_private) || super(method, include_private)
    end
  end
end
