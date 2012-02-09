# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Referenced #:nodoc:
        class Many < Builder

          # This builder either takes a hash and queries for the
          # object or an array of documents, where it will just return tem.
          #
          # @example Build the documents.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type The type of document to query for.
          #
          # @return [ Array<Document> ] The documents.
          def build(type = nil)
            return object unless query?
            return [] if object.is_a?(Array)
            crit = metadata.criteria(convertable(metadata, object))
            IdentityMap.get(crit.klass, crit.selector) || crit
          end

          private

          # Get the value for the foreign key in convertable or unconvertable
          # form.
          #
          # @example Get the value.
          #   builder.convertable
          #
          # @return [ String, BSON::ObjectId ] The string or object id.
          #
          # @since 2.0.2
          def convertable(metadata, object)
            inverse = metadata.inverse_klass
            if inverse.using_object_ids? || object.is_a?(BSON::ObjectId)
              object
            else
              object.tap do |obj|
                obj.unconvertable_to_bson = true if obj.is_a?(String)
              end
            end
          end
        end
      end
    end
  end
end
