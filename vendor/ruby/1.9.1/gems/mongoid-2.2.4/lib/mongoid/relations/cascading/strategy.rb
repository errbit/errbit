# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Cascading #:nodoc:
      class Strategy

        attr_accessor :document, :relation, :metadata

        # Initialize the new cascade strategy, which will set up the relation
        # and the metadata.
        #
        # @example Instantiate the strategy
        #   Strategy.new(document, metadata)
        #
        # @param [ Document ] document The document to cascade from.
        # @param [ Metadata ] metadata The relation's metadata.
        #
        # @return [ Strategy ] The new strategy.
        def initialize(document, metadata)
          @document, @metadata = document, metadata
          @relation = document.send(metadata.name)
        end
      end
    end
  end
end
