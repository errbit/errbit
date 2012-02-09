# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:

    # Contains common logic for delete operations.
    module Deletion

      # Wrap all the common delete logic for both root and embedded
      # documents and then yield to the block.
      #
      # @example Execute common delete logic.
      #   prepare do |doc|
      #     collection.remove({ :_id => "value })
      #   end
      #
      # @param [ Proc ] block The block to call.
      #
      # @return [ true ] Always true.
      #
      # @since 2.1.0
      def prepare(&block)
        document.cascade!
        yield(document)
        document.freeze
        document.destroyed = true
        IdentityMap.remove(document)
        Threaded.clear_safety_options!
        true
      end
    end
  end
end
