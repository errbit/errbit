# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:

    # This class wraps the MongoDB master database.
    class Master
      include Mongoid::Collections::Retry

      attr_reader :collection

      # All read and write operations should delegate to the master connection.
      # These operations mimic the methods on a Mongo:Collection.
      #
      # @example Proxy the driver save.
      #   collection.save({ :name => "Al" })
      Operations::ALL.each do |name|
        class_eval <<-EOS, __FILE__, __LINE__
          def #{name}(*args)
            retry_on_connection_failure do
              collection.#{name}(*args)
            end
          end
        EOS
      end

      # Create the new database writer. Will create a collection from the
      # master database.
      #
      # @example Create a new wrapped master.
      #   Master.new(db, "testing")
      #
      # @param [ Mongo::DB ] master The master database.
      # @param [ String ] name The name of the database.
      # @param [ Hash ] options The collection options.
      #
      # @option options [ true, false ] :capped If the collection is capped.
      # @option options [ Integer ] :size The capped collection size.
      # @option options [ Integer ] :max The maximum number of docs in the
      #   capped collection.
      def initialize(master, name, options = {})
        @collection = master.create_collection(name, options)
      end
    end
  end
end
