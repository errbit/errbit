# encoding: utf-8
module Mongoid #:nodoc:
  module Relations #:nodoc:
    module Targets #:nodoc:

      # This class is the wrapper for all relational associations that have a
      # target that can be a criteria or array of loaded documents. This
      # handles both cases or a combination of the two.
      class Enumerable
        include ::Enumerable

        # The three main instance variables are collections of documents.
        #
        # @attribute [rw] added Documents that have been appended.
        # @attribute [rw] loaded Persisted documents that have been loaded.
        # @attribute [rw] unloaded A criteria representing persisted docs.
        attr_accessor :added, :loaded, :unloaded

        delegate :===, :is_a?, :kind_of?, :to => :added

        # Check if the enumerable is equal to the other object.
        #
        # @example Check equality.
        #   enumerable == []
        #
        # @param [ Enumerable ] other The other enumerable.
        #
        # @return [ true, false ] If the objects are equal.
        #
        # @since 2.1.0
        def ==(other)
          return false unless other.respond_to?(:entries)
          entries == other.entries
        end

        # Append a document to the enumerable.
        #
        # @example Append the document.
        #   enumerable << document
        #
        # @param [ Document ] document The document to append.
        #
        # @return [ Document ] The document.
        #
        # @since 2.1.0
        def <<(document)
          added << document
        end
        alias :push :<<

        # Clears out all the documents in this enumerable. If passed a block it
        # will yield to each document that is in memory.
        #
        # @example Clear out the enumerable.
        #   enumerable.clear
        #
        # @example Clear out the enumerable with a block.
        #   enumerable.clear do |doc|
        #     doc.unbind
        #   end
        #
        # @return [ Array<Document> ] The cleared out added docs.
        #
        # @since 2.1.0
        def clear
          if block_given?
            in_memory { |doc| yield(doc) }
          end
          loaded.clear and added.clear
        end

        # Clones each document in the enumerable.
        #
        # @note This loads all documents into memory.
        #
        # @example Clone the enumerable.
        #   enumerable.clone
        #
        # @return [ Array<Document> ] An array clone of the enumerable.
        #
        # @since 2.1.6
        def clone
          collect { |doc| doc.clone }
        end

        # Delete the supplied document from the enumerable.
        #
        # @example Delete the document.
        #   enumerable.delete(document)
        #
        # @param [ Document ] document The document to delete.
        #
        # @return [ Document ] The deleted document.
        #
        # @since 2.1.0
        def delete(document)
          (loaded.delete(document) || added.delete(document)).tap do |doc|
            unless doc
              if unloaded && unloaded.where(:_id => document.id).exists?
                yield(document) if block_given?
                return document
              end
            end
            yield(doc) if block_given?
          end
        end

        # Deletes every document in the enumerable for where the block returns
        # true.
        #
        # @note This operation loads all documents from the database.
        #
        # @example Delete all matching documents.
        #   enumerable.delete_if do |doc|
        #     dod.id == id
        #   end
        #
        # @return [ Array<Document> ] The remaining docs.
        #
        # @since 2.1.0
        def delete_if(&block)
          load_all!
          tap do
            loaded.delete_if(&block)
            added.delete_if(&block)
          end
        end

        # Iterating over this enumerable has to handle a few different
        # scenarios.
        #
        # If the enumerable has its criteria loaded into memory then it yields
        # to all the loaded docs and all the added docs.
        #
        # If the enumerable has not loaded the criteria then it iterates over
        # the cursor while loading the documents and then iterates over the
        # added docs.
        #
        # @example Iterate over the enumerable.
        #   enumerable.each do |doc|
        #     puts doc
        #   end
        #
        # @return [ true ] That the enumerable is now loaded.
        #
        # @since 2.1.0
        def each
          if loaded?
            loaded.each do |doc|
              yield(doc)
            end
          else
            unloaded.each do |doc|
              loaded.push(doc)
              yield(doc)
            end
          end
          added.each do |doc|
            next if doc.persisted? && (!loaded? && !loaded.empty?)
            yield(doc)
          end
          @executed = true
        end

        # Is the enumerable empty? Will determine if the count is zero based on
        # whether or not it is loaded.
        #
        # @example Is the enumerable empty?
        #   enumerable.empty?
        #
        # @return [ true, false ] If the enumerable is empty.
        #
        # @since 2.1.0
        def empty?
          if loaded?
            in_memory.count == 0
          else
            unloaded.count + added.count == 0
          end
        end

        # Get the first document in the enumerable. Will check the persisted
        # documents first. Does not load the entire enumerable.
        #
        # @example Get the first document.
        #   enumerable.first
        #
        # @return [ Document ] The first document found.
        #
        # @since 2.1.0
        def first
          added.first || (loaded? ? loaded.first : unloaded.first)
        end

        # Initialize the new enumerable either with a criteria or an array.
        #
        # @example Initialize the enumerable with a criteria.
        #   Enumberable.new(Post.where(:person_id => id))
        #
        # @example Initialize the enumerable with an array.
        #   Enumerable.new([ post ])
        #
        # @param [ Criteria, Array<Document> ] target The wrapped object.
        #
        # @since 2.1.0
        def initialize(target)
          if target.is_a?(Criteria)
            @added, @loaded, @unloaded = [], [], target
          else
            @added, @executed, @loaded = [], true, target
          end
        end

        # Inspection will just inspect the entries for nice array-style
        # printing.
        #
        # @example Inspect the enumerable.
        #   enumerable.inspect
        #
        # @return [ String ] The inspected enum.
        #
        # @since 2.1.0
        def inspect
          entries.inspect
        end

        # Return all the documents in the enumerable that have been loaded or
        # added.
        #
        # @note When passed a block it yields to each document.
        #
        # @example Get the in memory docs.
        #   enumerable.in_memory
        #
        # @return [ Array<Document> ] The in memory docs.
        #
        # @since 2.1.0
        def in_memory
          (loaded + added).tap do |docs|
            docs.each { |doc| yield(doc) } if block_given?
          end
        end

        # Get the last document in the enumerable. Will check the new
        # documents first. Does not load the entire enumerable.
        #
        # @example Get the last document.
        #   enumerable.last
        #
        # @return [ Document ] The last document found.
        #
        # @since 2.1.0
        def last
          added.last || (loaded? ? loaded.last : unloaded.last)
        end

        # Loads all the documents in the enumerable from the database.
        #
        # @example Load all the documents.
        #   enumerable.load_all!
        #
        # @return [ true ] That the enumerable is loaded.
        #
        # @since 2.1.0
        alias :load_all! :entries

        # Has the enumerable been loaded? This will be true if the criteria has
        # been executed or we manually load the entire thing.
        #
        # @example Is the enumerable loaded?
        #   enumerable.loaded?
        #
        # @return [ true, false ] If the enumerable has been loaded.
        #
        # @since 2.1.0
        def loaded?
          !!@executed
        end

        # Reset the enumerable back to it's persisted state.
        #
        # @example Reset the enumerable.
        #   enumerable.reset
        #
        # @return [ false ] Always false.
        #
        # @since 2.1.0
        def reset
          loaded.clear and added.clear
          @executed = false
        end

        # Does this enumerable respond to the provided method?
        #
        # @example Does the enumerable respond to the method?
        #   enumerable.respond_to?(:sum)
        #
        # @param [ String, Symbol ] name The name of the method.
        # @param [ true, false ] include_private Whether to include private
        #   methods.
        #
        # @return [ true, false ] Whether the enumerable responds.
        #
        # @since 2.1.0
        def respond_to?(name, include_private = false)
          [].respond_to?(name, include_private) || super
        end

        # Gets the total size of this enumerable. This is a combination of all
        # the persisted and unpersisted documents.
        #
        # @example Get the size.
        #   enumerable.size
        #
        # @return [ Integer ] The size of the enumerable.
        #
        # @since 2.1.0
        def size
          (unloaded ? unloaded.count : loaded.count) + added.count{ |d| d.new? }
        end
        alias :length :size

        # Send #to_json to the entries.
        #
        # @example Get the enumerable as json.
        #   enumerable.to_json
        #
        # @param [ Hash ] options Optional parameters.
        #
        # @return [ String ] The entries all loaded as a string.
        #
        # @since 2.2.0
        def to_json(options = {})
          entries.to_json(options)
        end

        # Send #as_json to the entries, without encoding.
        #
        # @example Get the enumerable as json.
        #   enumerable.as_json
        #
        # @param [ Hash ] options Optional parameters.
        #
        # @return [ Hash ] The entries all loaded as a hash.
        #
        # @since 2.2.0
        def as_json(options = {})
          entries.as_json(options)
        end

        # Return all the unique documents in the enumerable.
        #
        # @note This operation loads all documents from the database.
        #
        # @example Get all the unique documents.
        #   enumerable.uniq
        #
        # @return [ Array<Document> ] The unique documents.
        #
        # @since 2.1.0
        def uniq
          entries.uniq
        end

        private

        def method_missing(name, *args, &block)
          entries.send(name, *args, &block)
        end
      end
    end
  end
end
