# encoding: utf-8
require "mongoid/collections/retry"
require "mongoid/collections/operations"
require "mongoid/collections/master"

module Mongoid #:nodoc

  # This class is the Mongoid wrapper to the Mongo Ruby driver's collection
  # object.
  class Collection
    attr_reader :counter, :klass, :name

    # All write operations should delegate to the master connection. These
    # operations mimic the methods on a Mongo:Collection.
    #
    # @example Delegate the operation.
    #   collection.save({ :name => "Al" })
    delegate *(Collections::Operations::PROXIED.dup << {:to => :master})

    # Get the unwrapped driver collection for this mongoid collection.
    #
    # @example Get the driver collection.
    #   collection.driver
    #
    # @return [ Mongo::Collection ] The driver collection.
    #
    # @since 2.2.0
    def driver
      master.collection
    end

    # Find documents from the database given a selector and options.
    #
    # @example Find documents in the collection.
    #   collection.find({ :test => "value" })
    #
    # @param [ Hash ] selector The query selector.
    # @param [ Hash ] options The options to pass to the db.
    #
    # @return [ Cursor ] The results.
    def find(selector = {}, options = {})
      cursor = Mongoid::Cursor.new(klass, self, master(options).find(selector, options))
      if block_given?
        yield cursor; cursor.close
      else
        cursor
      end
    end

    # Find the first document from the database given a selector and options.
    #
    # @example Find one document.
    #   collection.find_one({ :test => "value" })
    #
    # @param [ Hash ] selector The query selector.
    # @param [ Hash ] options The options to pass to the db.
    #
    # @return [ Document, nil ] A matching document or nil if none found.
    def find_one(selector = {}, options = {})
      master(options).find_one(selector, options)
    end

    # Initialize a new Mongoid::Collection, setting up the master, slave, and
    # name attributes. Masters will be used for writes, slaves for reads.
    #
    # @example Create the new collection.
    #   Collection.new(masters, slaves, "test")
    #
    # @param [ Class ] klass The class the collection is for.
    # @param [ String ] name The name of the collection.
    # @param [ Hash ] options The collection options.
    #
    # @option options [ true, false ] :capped If the collection is capped.
    # @option options [ Integer ] :size The capped collection size.
    # @option options [ Integer ] :max The maximum number of docs in the
    #   capped collection.
    def initialize(klass, name, options = {})
      @klass, @name, @options = klass, name, options || {}
    end

    # Inserts one or more documents in the collection.
    #
    # @example Insert documents.
    #   collection.insert(
    #     { "field" => "value" },
    #     :safe => true
    #   )
    #
    # @param [ Hash, Array<Hash> ] documents A single document or multiples.
    # @param [ Hash ] options The options.
    #
    # @since 2.0.2, batch-relational-insert
    def insert(documents, options = {})
      consumer = Threaded.insert
      if consumer
        consumer.consume(documents, options)
      else
        master(options).insert(documents, options)
      end
    end

    # Perform a map/reduce on the documents.
    #
    # @example Perform the map/reduce.
    #   collection.map_reduce(map, reduce)
    #
    # @param [ String ] map The map javascript function.
    # @param [ String ] reduce The reduce javascript function.
    # @param [ Hash ] options The options to pass to the db.
    #
    # @return [ Cursor ] The results.
    def map_reduce(map, reduce, options = {})
      master(options).map_reduce(map, reduce, options)
    end
    alias :mapreduce :map_reduce

    # Return the object responsible for writes to the database. This will
    # always return a collection associated with the Master DB.
    #
    # @example Get the master connection.
    #   collection.master
    #
    # @return [ Master ] The master connection.
    def master(options = {})
      options.delete(:cache)
      db = Mongoid.databases[klass.database] || Mongoid.master
      @master ||= Collections::Master.new(db, @name, @options)
    end

    # Updates one or more documents in the collection.
    #
    # @example Update documents.
    #   collection.update(
    #     { "_id" => BSON::OjectId.new },
    #     { "$push" => { "addresses" => { "_id" => "street" } } },
    #     :safe => true
    #   )
    #
    # @param [ Hash ] selector The document selector.
    # @param [ Hash ] document The modifier.
    # @param [ Hash ] options The options.
    #
    # @since 2.0.0
    def update(selector, document, options = {})
      updater = Threaded.update_consumer(klass)
      if updater
        updater.consume(selector, document, options)
      else
        master(options).update(selector, document, options)
      end
    end
  end
end
