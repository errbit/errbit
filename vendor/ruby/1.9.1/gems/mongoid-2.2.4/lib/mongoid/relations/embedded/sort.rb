# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:

      # This module handles embedded associations sorting
      # Since mongodb doesn't have virtual collection for embedded docs yet
      # (see https://jira.mongodb.org/browse/SERVER-142 for details)
      # Sorting implemented in ruby
	    # This can be a performance killer on collections with many embedded documents
	    module Sort

        # Sorts documents
        #
        # @param [ Array<Documents> ] documents array of documents
        # @param [ Mongoid::Relations::Metadata ] metadata association metadata
        def sort_documents!(documents, metadata)
          sort_options = Criteria.new(metadata.klass).order_by(metadata.order).options[:sort]

          docs = documents.sort_by do |document|
            sort_options.map do |key, direction|
              Contexts::Enumerable::Sort.new(document.read_attribute(key), direction)
            end
          end
          documents.replace(docs)
        end
	    end
    end
  end
end

