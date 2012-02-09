require "heroku/plugin"

module Heroku
  class BuiltinPlugin < Plugin
    def self.directory
      File.expand_path("../../../plugins", __FILE__)
    end
  end
end
