# encoding: utf-8
module Mongoid #:nodoc:
  module Atomic #:nodoc:
    module Paths #:nodoc:

      # This class encapsulates behaviour for locating and updating root
      # documents atomically.
      class Root

        attr_reader :document, :path, :position

        # Create the new root path utility.
        #
        # @example Create the root path util.
        #   Root.new(document)
        #
        # @param [ Document ] document The document to generate the paths for.
        #
        # @since 2.1.0
        def initialize(document)
          @document, @path, @position = document, "", ""
        end

        # Get the selector to use for the root document when performing atomic
        # updates. When sharding this will include the shard key.
        #
        # @example Get the selector.
        #   root.selector
        #
        # @return [ Hash ] The selector to identify the document with.
        #
        # @since 2.1.0
        def selector
          { "_id" => document.identifier || document._id }.
            merge!(document.shard_key_selector)
        end
      end
    end
  end
end
