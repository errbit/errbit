# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # Superclass for all objects that bind relations together.
    class Binding
      attr_reader :base, :target, :metadata

      # Execute a block in binding mode.
      #
      # @example Execute in binding mode.
      #   binding do
      #     relation.push(doc)
      #   end
      #
      # @return [ Object ] The return value of the block.
      #
      # @since 2.1.0
      def binding
        Threaded.begin_bind
        yield
      ensure
        Threaded.exit_bind
      end

      # Is the current thread in binding mode?
      #
      # @example Is the thread in binding mode?
      #   binding.binding?
      #
      # @return [ true, false ] If the thread is binding.
      #
      # @since 2.1.0
      def binding?
        Threaded.binding?
      end

      # Create the new binding.
      #
      # @example Initialize a binding.
      #   Binding.new(base, target, metadata)
      #
      # @param [ Document ] base The base of the binding.
      # @param [ Document, Array<Document> ] target The target of the binding.
      # @param [ Metadata ] metadata The relation's metadata.
      #
      # @since 2.0.0.rc.1
      def initialize(base, target, metadata)
        @base, @target, @metadata = base, target, metadata
      end
    end
  end
end
