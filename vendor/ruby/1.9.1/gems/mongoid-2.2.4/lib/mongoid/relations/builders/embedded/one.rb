# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Embedded #:nodoc:
        class One < Builder #:nodoc:

          # Builds the document out of the attributes using the provided
          # metadata on the relation. Instantiates through the factory in order
          # to make sure subclasses and allocation are used if fitting.
          #
          # @example Build the document.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type Not used in this context.
          #
          # @return [ Document ] A single document.
          def build(type = nil)
            return object unless object.is_a?(Hash)
            if loading
              Mongoid::Factory.from_db(metadata.klass, object)
            else
              Mongoid::Factory.build(metadata.klass, object)
            end
          end
        end
      end
    end
  end
end
