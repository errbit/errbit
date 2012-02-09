require 'ruby_fogbugz/adapters/http/typhoeus'
require 'ruby_fogbugz/adapters/xml/cracker'
require 'ruby_fogbugz/interface'

module Fogbugz
  class << self
    attr_accessor :adapter
  end

  self.adapter = {
    :xml  => Adapter::XML::Cracker,
    :http => Adapter::HTTP::Typhoeuser
  }
end
