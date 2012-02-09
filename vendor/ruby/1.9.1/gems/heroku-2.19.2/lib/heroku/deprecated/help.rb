require "heroku/deprecated"

module Heroku::Deprecated::Help
  def self.included(base)
    base.extend ClassMethods
  end

  class HelpGroup < Array
    attr_reader :title

    def initialize(title)
      @title = title
    end

    def command(name, description)
      self << [name, description]
    end

    def space
      self << ['', '']
    end
  end

  module ClassMethods
    def groups
      @groups ||= []
    end

    def group(title, &block)
      groups << begin
        group = HelpGroup.new(title)
        yield group
        group
      end
    end
  end
end

