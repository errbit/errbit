# encoding: utf-8
module Mongoid #:nodoc

  # Mongoid wrapper of the Ruby Driver cursor.
  class Cursor
    include Mongoid::Collections::Retry
    include Enumerable

    # Operations on the Mongo::Cursor object that will not get overriden by the
    # Mongoid::Cursor are defined here.
    OPERATIONS = [
      :close,
      :closed?,
      :count,
      :explain,
      :fields,
      :full_collection_name,
      :hint,
      :limit,
      :order,
      :query_options_hash,
      :query_opts,
      :selector,
      :skip,
      :snapshot,
      :sort,
      :timeout
    ]

    attr_reader :collection, :cursor, :klass

    # The operations above will all delegate to the proxied Mongo::Cursor.
    OPERATIONS.each do |name|
      class_eval <<-EOS, __FILE__, __LINE__
        def #{name}(*args)
          retry_on_connection_failure do
            cursor.#{name}(*args)
          end
        end
      EOS
    end

    # Iterate over each document in the cursor and yield to it.
    #
    # @example Iterate over the cursor.
    #   cursor.each { |doc| p doc.title }
    def each
      cursor.each do |document|
        yield Mongoid::Factory.from_db(klass, document)
      end
    end

    # Create the new +Mongoid::Cursor+.
    #
    # @example Instantiate the cursor.
    #   Mongoid::Cursor.new(Person, cursor)
    #
    # @param [ Class ] klass The class associated with the cursor.
    # @param [ Collection ] collection The Mongoid::Collection instance.
    # @param [ Mongo::Cursor ] cursor The Mongo::Cursor to be proxied.
    def initialize(klass, collection, cursor)
      @klass, @collection, @cursor = klass, collection, cursor
    end

    # Return the next document in the cursor. Will instantiate a new Mongoid
    # document with the attributes.
    #
    # @example Get the next document.
    #   cursor.next_document
    #
    # @return [ Document ] The next document in the cursor.
    def next_document
      Mongoid::Factory.from_db(klass, cursor.next_document)
    end

    # Returns an array of all the documents in the cursor.
    #
    # @example Get the cursor as an array.
    #   cursor.to_a
    #
    # @return [ Array<Document> ] An array of documents.
    def to_a
      cursor.to_a.collect { |attrs| Mongoid::Factory.from_db(klass, attrs) }
    end
  end
end
