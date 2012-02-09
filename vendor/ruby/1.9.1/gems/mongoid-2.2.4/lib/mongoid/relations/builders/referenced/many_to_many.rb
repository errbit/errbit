# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Referenced #:nodoc:
        class ManyToMany < Builder

          # This builder either takes a hash and queries for the
          # object or an array of documents, where it will just return them.
          #
          # @example Build the documents.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type The type of document to query for.
          #
          # @return [ Array<Document> ] The documents.
          def build(type = nil)
            return object.try(:dup) unless query?
            metadata.criteria(object)
          end

          # Do we need to perform a database query? It will be so if the object we
          # have is not a document.
          #
          # @example Should we query the database?
          #   builder.query?
          #
          # @return [ true, false ] Whether a database query should happen.
          #
          # @since 2.0.0.rc.1
          def query?
            object.nil? || !object.first.is_a?(Mongoid::Document)
          end
        end
      end
    end
  end
end
