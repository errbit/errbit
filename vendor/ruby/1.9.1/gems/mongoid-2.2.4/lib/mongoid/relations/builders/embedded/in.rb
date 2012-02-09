# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Embedded #:nodoc:
        class In < Builder #:nodoc:

          # This builder doesn't actually build anything, just returns the
          # parent since it should already be instantiated.
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
