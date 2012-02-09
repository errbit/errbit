# encoding: utf-8
module Mongoid #:nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:
      module Atomic #:nodoc:

        class Pull < Operation

          # Get the merged operations for the single atomic set.
          #
          # @example Get the operations
          #   set.operations
          #
          # @return [ Hash ] The pull operations.
          #
          # @since 2.0.0
          def operations
            { "$pull" =>
              { path =>
                { "_id" =>
                  { "$in" => documents.map { |doc| doc["_id"] } }
                }
              }
            }
          end

          private

          # Parses the incoming operations to get the documents to set.
          #
          # @example Parse the operations.
          #   set.parse(
          #     { "$pull" => { "addresses" => { "_id" => "street" } } }
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
          #   set.extract({ "$pull" => [{ "_id" => "street" }] })
          #
          # @param [ Hash ] operation The op to extract from.
          #
          # @since 2.0.0
          def extract(modifier, operations)
            @path = operations.keys.first
            case modifier
            when "$pull"
              documents.push(operations[path])
            when "$pullAll"
              documents.concat(operations[path])
            end
          end
        end
      end
    end
  end
end
