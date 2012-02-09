# encoding: utf-8
module Mongoid #:nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:
      module Atomic #:nodoc:

        class Set < Operation

          # Get the merged operations for the single atomic set.
          #
          # @example Get the operations
          #   set.operations
          #
          # @return [ Hash ] The set operations.
          #
          # @since 2.0.0
          def operations
            { "$set" => { path => documents } }
          end

          private

          # Parses the incoming operations to get the documents to set.
          #
          # @example Parse the operations.
          #   set.parse(
          #     { "addresses" => { "$pushAll" => [{ "_id" => "street" }] } }
          #   )
          #
          # @param [ Hash ] operations The ops to parse.
          #
          # @since 2.0.0
          def parse(operations)
            modifier = operations.keys.first
            extract(modifier, operations[modifier])
          end

          # Extract a document from the operation.
          #
          # @example Extract the document.
          #   set.extract({ "$pushAll" => [{ "_id" => "street" }] })
          #
          # @param [ Hash ] operation The op to extract from.
          #
          # @since 2.0.0
          def extract(modifier, operations)
            @path = operations.keys.first
            case modifier
            when "$push"
              documents.push(operations[path])
            when "$pushAll"
              documents.push(operations[path].first)
            when "$set"
              @documents = operations[path]
            end
          end
        end
      end
    end
  end
end
