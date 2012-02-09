# encoding: utf-8
module Mongoid #:nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:
      module Atomic #:nodoc:

        class Unset < Operation

          # Get the merged operations for the single atomic set.
          #
          # @example Get the operations
          #   set.operations
          #
          # @return [ Hash ] The set operations.
          #
          # @since 2.0.0
          def operations
            { "$unset" => { path => true } }
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
            @path ||= operations[modifier].keys.first
          end
        end
      end
    end
  end
end
