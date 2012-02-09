require 'user_agent/browsers/all'
require 'user_agent/browsers/gecko'
require 'user_agent/browsers/internet_explorer'
require 'user_agent/browsers/opera'
require 'user_agent/browsers/webkit'

class UserAgent
  module Browsers
    Security = {
      "N" => :none,
      "U" => :strong,
      "I" => :weak
    }.freeze

    def self.all
      [InternetExplorer, Webkit, Opera, Gecko]
    end

    def self.extend(array)
      array.extend(All)
      all.each do |extension|
        return array.extend(extension) if extension.extend?(array)
      end
    end
  end
end
