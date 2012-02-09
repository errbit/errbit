# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Referenced #:nodoc:
        class In < Builder

          # This builder either takes a foreign key and queries for the
          # object or a document, where it will just return it.
          #
          # @example Build the document.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type The type of document to query for.
          #
          # @return [ Document ] A single document.
          def build(type = nil)
            return object unless query?
            model = type ? type.constantize : metadata.klass
            IdentityMap.get(model, object) || metadata.criteria(object, model).first
          end
        end
      end
    end
  end
end
