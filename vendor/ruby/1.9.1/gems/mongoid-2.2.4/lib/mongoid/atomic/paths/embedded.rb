# encoding: utf-8
require "mongoid/atomic/paths/embedded/one"
require "mongoid/atomic/paths/embedded/many"

module Mongoid #:nodoc:
  module Atomic #:nodoc:
    module Paths #:nodoc:

      # Common functionality between the two different embedded paths.
      module Embedded

        attr_reader :delete_modifier, :document, :insert_modifier, :parent

        # Get the path to the document in the hierarchy.
        #
        # @example Get the path.
        #   many.path
        #
        # @return [ String ] The path to the document.
        #
        # @since 2.1.0
        def path
          position.sub(/\.\d+$/, "")
        end

        # Get the selector to use for the root document when performing atomic
        # updates. When sharding this will include the shard key.
        #
        # @example Get the selector.
        #   many.selector
        #
        # @return [ Hash ] The selector to identify the document with.
        #
        # @since 2.1.0
        def selector
          parent.atomic_selector.
            merge!({ "#{path}._id" => document.identifier || document._id }).
            merge!(document.shard_key_selector)
        end
      end
    end
  end
end
