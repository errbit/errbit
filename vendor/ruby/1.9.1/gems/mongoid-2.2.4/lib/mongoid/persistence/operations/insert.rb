# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Operations #:nodoc:

      # Insert is a persistence command responsible for taking a document that
      # has not been saved to the database and saving it.
      #
      # The underlying query resembles the following MongoDB query:
      #
      #   collection.insert(
      #     { "_id" : 1, "field" : "value" },
      #     false
      #   );
      class Insert
        include Insertion, Operations

        # Insert the new document in the database. This delegates to the standard
        # MongoDB collection's insert command.
        #
        # @example Insert the document.
        #   Insert.persist
        #
        # @return [ Document ] The document to be inserted.
        def persist
          prepare do |doc|
            collection.insert(doc.as_document, options)
            IdentityMap.set(doc)
          end
        end
      end
    end
  end
end
