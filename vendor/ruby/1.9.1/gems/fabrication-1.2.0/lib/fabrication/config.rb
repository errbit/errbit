module Fabrication
  module Config
    extend self

    def configure
      yield self
    end

    def fabricator_dir
      OPTIONS[:fabricator_dir]
    end

    def fabricator_dir=(folders)
      OPTIONS[:fabricator_dir] = (Array.new << folders).flatten
    end

    def reset_defaults
      OPTIONS.clear
      OPTIONS.merge!(DEFAULTS)
    end

    private

    DEFAULTS = {
      :fabricator_dir => ['test', 'spec']
    }
    OPTIONS = {}.merge!(DEFAULTS)
  end
end
