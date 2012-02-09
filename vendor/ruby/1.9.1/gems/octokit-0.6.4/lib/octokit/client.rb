require 'octokit/authentication'
require 'octokit/connection'
require 'octokit/repository'
require 'octokit/request'

require 'octokit/client/commits'
require 'octokit/client/issues'
require 'octokit/client/network'
require 'octokit/client/milestones'
require 'octokit/client/objects'
require 'octokit/client/organizations'
require 'octokit/client/pub_sub_hubbub'
require 'octokit/client/pub_sub_hubbub/service_hooks'
require 'octokit/client/pulls'
require 'octokit/client/repositories'
require 'octokit/client/timelines'
require 'octokit/client/users'

module Octokit
  class Client
    attr_accessor *Configuration::VALID_OPTIONS_KEYS

    def initialize(options={})
      options = Octokit.options.merge(options)
      Configuration::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", options[key])
      end
    end

    include Octokit::Authentication
    include Octokit::Connection
    include Octokit::Request

    include Octokit::Client::Commits
    include Octokit::Client::Issues
    include Octokit::Client::Network
    include Octokit::Client::Milestones
    include Octokit::Client::Objects
    include Octokit::Client::Organizations
    include Octokit::Client::Pulls
    include Octokit::Client::PubSubHubbub
    include Octokit::Client::PubSubHubbub::ServiceHooks
    include Octokit::Client::Repositories
    include Octokit::Client::Timelines
    include Octokit::Client::Users
  end
end
