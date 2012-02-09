# encoding: utf-8

require "mongoid/relations/embedded/sort"

module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module Embedded #:nodoc:
        class Many < Builder #:nodoc:
          include Relations::Embedded::Sort
          # Builds the document out of the attributes using the provided
          # metadata on the relation. Instantiates through the factory in order
          # to make sure subclasses and allocation are used if fitting. This
          # case will return many documents.
          #
          # @example Build the documents.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type Not used in this context.
          #
          # @return [ Array<Document ] The documents.
          def build(type = nil)
            return [] if object.blank?
            return object if object.first.is_a?(Document)
            [].tap do |docs|
              object.each do |attrs|
                if loading
                  docs << Mongoid::Factory.from_db(metadata.klass, attrs)
                else
                  docs << Mongoid::Factory.build(metadata.klass, attrs)
                end
              end
              sort_documents!(docs, metadata) if metadata.order
            end
          end
        end
      end
    end
  end
end
