# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Operations #:nodoc:
      module Embedded #:nodoc:

        # Insert is a persistence command responsible for taking a document that
        # has not been saved to the database and saving it. This specific class
        # handles the case when the document is embedded in another.
        #
        # The underlying query resembles the following MongoDB query:
        #
        #   collection.update(
        #     { "_id" : 1 },
        #     { "$push" : { "field" : "value" } },
        #     false
        #   );
        class Insert
          include Insertion, Operations

          # Insert the new document in the database. If the document's parent is a
          # new record, we will call save on the parent, otherwise we will $push
          # the document onto the parent.
          #
          # @example Insert an embedded document.
          #   Insert.persist
          #
          # @return [ Document ] The document to be inserted.
          def persist
            prepare do
              if parent.new?
                parent.insert
              else
                collection.update(parent.atomic_selector, inserts, options)
              end
            end
          end
        end
      end
    end
  end
end
