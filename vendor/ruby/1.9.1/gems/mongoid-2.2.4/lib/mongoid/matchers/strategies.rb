# encoding: utf-8
require "mongoid/matchers/default"
require "mongoid/matchers/all"
require "mongoid/matchers/exists"
require "mongoid/matchers/gt"
require "mongoid/matchers/gte"
require "mongoid/matchers/in"
require "mongoid/matchers/lt"
require "mongoid/matchers/lte"
require "mongoid/matchers/ne"
require "mongoid/matchers/nin"
require "mongoid/matchers/or"
require "mongoid/matchers/size"

module Mongoid #:nodoc:
  module Matchers #:nodoc:

    # This module is responsible for returning the correct matcher given a
    # MongoDB query expression.
    module Strategies
      extend self

      MATCHERS = {
        "$all" => Matchers::All,
        "$exists" => Matchers::Exists,
        "$gt" => Matchers::Gt,
        "$gte" => Matchers::Gte,
        "$in" => Matchers::In,
        "$lt" => Matchers::Lt,
        "$lte" => Matchers::Lte,
        "$ne" => Matchers::Ne,
        "$nin" => Matchers::Nin,
        "$or" => Matchers::Or,
        "$size" => Matchers::Size
      }

      # Get the matcher for the supplied key and value. Will determine the class
      # name from the key.
      #
      # @example Get the matcher.
      #   document.matcher(:title, { "$in" => [ "test" ] })
      #
      # @param [ Document ] document The document to check.
      # @param [ Symbol, String ] key The field name.
      # @param [ Object, Hash ] The value or selector.
      #
      # @return [ Matcher ] The matcher.
      #
      # @since 2.0.0.rc.7
      def matcher(document, key, value)
        if value.is_a?(Hash)
          MATCHERS[value.keys.first].new(extract_attribute(document, key))
        else
          if key == "$or"
            Matchers::Or.new(value, document)
          else
            Default.new(extract_attribute(document, key))
          end
        end
      end

      private

      # Extract the attribute from the key, being smarter about dot notation.
      #
      # @example Extract the attribute.
      #   strategy.extract_attribute(doc, "info.field")
      #
      # @param [ Document ] document The document.
      # @param [ String ] key The key.
      #
      # @return [ Object ] The value of the attribute.
      #
      # @since 2.2.1
      def extract_attribute(document, key)
        if (key_string = key.to_s) =~ /.+\..+/
          key_string.split('.').inject(document.attributes) do |attribs, key|
            attribs.try(:[], key)
          end
        else
          document.attributes[key_string]
        end
      end
    end
  end
end
