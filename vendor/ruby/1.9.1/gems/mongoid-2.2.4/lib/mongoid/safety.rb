# encoding: utf-8
module Mongoid #:nodoc:

  # The +Safety+ module is used to provide a DSL to execute database operations
  # in safe mode on a per query basis, either from the +Document+ class level
  # or instance level.
  module Safety
    extend ActiveSupport::Concern

    # Execute the following class-level persistence operation in safe mode.
    #
    # @example Upsert in safe mode.
    #   person.safely.upsert
    #
    # @example Destroy in safe mode with w and fsync options.
    #   person.safely(:w => 2, :fsync => true).destroy
    #
    # @param [ Hash ] options The safe mode options.
    #
    # @option options [ Integer ] :w The number of nodes to write to.
    # @option options [ Integer ] :wtimeout Time to wait for return from all
    #   nodes.
    # @option options [ true, false ] :fsync Should a fsync occur.
    #
    # @return [ Proxy ] The safety proxy.
    def safely(safety = true)
      tap { Threaded.safety_options = safety }
    end

    class << self

      # Static class method of easily getting the desired safe mode options
      # from anywhere in the framework.
      #
      # @example Get the options with safe mode included.
      #   Safety.merge_safety_options({ :safe => false })
      #
      # @param [ Hash ] options The persistence options.
      #
      # @return [ Hash ] The options hash.
      #
      # @since 2.1.0
      def merge_safety_options(options = {})
        options ||= {}
        return options if options[:safe]
        options.merge!(
          { :safe => Threaded.safety_options || Mongoid.persist_in_safe_mode }
        )
      end
    end

    module ClassMethods #:nodoc:

      # Execute the following class-level persistence operation in safe mode.
      #
      # @example Create in safe mode.
      #   Person.safely.create(:name => "John")
      #
      # @example Delete all in safe mode with options.
      #   Person.safely(:w => 2, :fsync => true).delete_all
      #
      # @param [ Hash ] options The safe mode options.
      #
      # @option options [ Integer ] :w The number of nodes to write to.
      # @option options [ Integer ] :wtimeout Time to wait for return from all
      #   nodes.
      # @option options [ true, false ] :fsync Should a fsync occur.
      #
      # @return [ Proxy ] The safety proxy.
      def safely(safety = true)
        tap { Threaded.safety_options = safety }
      end
    end
  end
end
