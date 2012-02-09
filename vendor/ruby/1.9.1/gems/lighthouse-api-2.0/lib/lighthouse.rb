$: << File.dirname(__FILE__) unless $:.include?(File.dirname(__FILE__))

require 'rubygems'
require 'lighthouse/core_ext/uri'
require 'active_support'
require 'active_resource'

# required for ruby < 1.9. constants(false) emaulation in active_support is buggy.
require 'lighthouse/base'

# Ruby lib for working with the Lighthouse API's XML interface.  
# The first thing you need to set is the account name.  This is the same
# as the web address for your account.
#
#   Lighthouse.account = 'activereload'
#
# Then, you should set the authentication.  You can either use your login
# credentials with HTTP Basic Authentication or with an API Tokens.  You can
# find more info on tokens at http://lighthouseapp.com/help/using-beacons.
#
#   # with basic authentication
#   Lighthouse.authenticate('rick@techno-weenie.net', 'spacemonkey')
#
#   # or, use a token
#   Lighthouse.token = 'abcdefg'
#
# If no token or authentication info is given, you'll only be granted public access.
#
# This library is a small wrapper around the REST interface.  You should read the docs at
# http://lighthouseapp.com/api.
#
module Lighthouse
  
  extend ActiveSupport::Autoload
  
  autoload :Bin
  autoload :Changeset
  autoload :Membership
  autoload :Message
  autoload :Milestone
  autoload :Project
  autoload :ProjectMembership
  autoload :Tag
  autoload :TagResource
  autoload :Ticket
  autoload :Token
  autoload :User
  
  class Error < StandardError; end
  
  class Change < Array; end
  
  class << self
    attr_accessor :account, :email, :password, :host_format, :domain_format, :protocol, :port
    attr_reader :token

    # Sets up basic authentication credentials for all the resources.
    def authenticate(email, password)
      self.email    = email
      self.password = password
      
      resources.each do |klass|
        update_auth(klass)
      end
    end

    # Sets the API token for all the resources.
    def token=(value)
      @token = value
      resources.each do |klass|
        update_token_header(klass)
      end
    end

    def resources
      @resources ||= []
    end
    
    def update_site(resource)
      resource.site = resource.site_format % (host_format % [protocol, domain_format % account, ":#{port}"])
    end
    
    def update_token_header(resource)
      resource.headers['X-LighthouseToken'] = token if token
    end
    
    def update_auth(resource)
      return unless email && password
      resource.user     = email
      resource.password = password
    end
  end
  
  self.host_format   = '%s://%s%s'
  self.domain_format = '%s.lighthouseapp.com'
  self.protocol      = 'http'
  self.port          = ''
end
