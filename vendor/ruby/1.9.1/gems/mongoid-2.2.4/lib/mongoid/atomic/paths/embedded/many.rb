# encoding: utf-8
module Mongoid #:nodoc:
  module Atomic #:nodoc:
    module Paths #:nodoc:
      module Embedded #:nodoc:

        # This class encapsulates behaviour for locating and updating
        # documents that are defined as an embedded 1-n.
        class Many
          include Embedded

          # Create the new path utility.
          #
          # @example Create the path util.
          #   Many.new(document)
          #
          # @param [ Document ] document The document to generate the paths for.
          #
          # @since 2.1.0
          def initialize(document)
            @document, @parent = document, document._parent
            @insert_modifier, @delete_modifier ="$push", "$pull"
          end

          # Get the position of the document in the hierarchy. This will
          # include indexes of 1-n embedded relations that may sit above the
          # embedded many.
          #
          # @example Get the position.
          #   many.position
          #
          # @return [ String ] The position of the document.
          #
          # @since 2.1.0
          def position
            pos = parent.atomic_position
            locator = document.new? ? "" : ".#{document._index}"
            "#{pos}#{"." unless pos.blank?}#{document.metadata.name}#{locator}"
          end
        end
      end
    end
  end
end
