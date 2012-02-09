# encoding: utf-8
require "mongoid/matchers/strategies"

module Mongoid #:nodoc:

  # This module contains all the behavior for ruby implementations of MongoDB
  # selectors.
  module Matchers

    # Determines if this document has the attributes to match the supplied
    # MongoDB selector. Used for matching on embedded associations.
    #
    # @example Does the document match?
    #   document.matches?(:title => { "$in" => [ "test" ] })
    #
    # @param [ Hash ] selector The MongoDB selector.
    #
    # @return [ true, false ] True if matches, false if not.
    def matches?(selector)
      selector.each_pair do |key, value|
        if value.is_a?(Hash)
          value.each do |item|
            return false unless Strategies.matcher(self, key, Hash[*item]).matches?(Hash[*item])
          end
        else
          return false unless Strategies.matcher(self, key, value).matches?(value)
        end
      end
      return true
    end
  end
end
