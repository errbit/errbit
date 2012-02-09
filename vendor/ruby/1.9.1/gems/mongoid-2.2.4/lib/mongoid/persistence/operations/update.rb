# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Operations #:nodoc:

      # Update is a persistence command responsible for taking a document that
      # has already been saved to the database and saving it, depending on
      # whether or not the document has been modified.
      #
      # Before persisting the command will check via dirty attributes if the
      # document has changed, if not, it will simply return true. If it has it
      # will go through the validation steps, run callbacks, and set the changed
      # fields atomically on the document. The underlying query resembles the
      # following MongoDB query:
      #
      #   collection.update(
      #     { "_id" : 1,
      #     { "$set" : { "field" : "value" },
      #     false,
      #     false
      #   );
      #
      # For embedded documents it will use the positional locator:
      #
      #   collection.update(
      #     { "_id" : 1, "addresses._id" : 2 },
      #     { "$set" : { "addresses.$.field" : "value" },
      #     false,
      #     false
      #   );
      #
      class Update
        include Modification, Operations

        # Persist the document that is to be updated to the database. This will
        # only write changed fields via MongoDB's $set modifier operation.
        #
        # @example Update the document.
        #   Update.persist
        #
        # @return [ true, false ] If the save passed.
        def persist
          prepare do
            unless updates.empty?
              collection.update(selector, updates, options)
              conflicts.each_pair do |key, value|
                collection.update(selector, { key => value }, options)
              end
            end
          end
        end
      end
    end
  end
end
