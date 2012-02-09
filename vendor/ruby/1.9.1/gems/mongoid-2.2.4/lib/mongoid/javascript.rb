# encoding: utf-8
module Mongoid #:nodoc:
  class Javascript
    # Constant for the file that defines all the js functions.
    FUNCTIONS = File.join(File.dirname(__FILE__), "javascript", "functions.yml")

    # Load the javascript functions and define a class method for each one,
    # that memoizes the value.
    #
    # @example Get the function.
    #   Mongoid::Javascript.aggregate
    YAML.load(File.read(FUNCTIONS)).each_pair do |key, function|
      (class << self; self; end).class_eval <<-EOT
        def #{key}
          @#{key} ||= "#{function}"
        end
      EOT
    end
  end
end
