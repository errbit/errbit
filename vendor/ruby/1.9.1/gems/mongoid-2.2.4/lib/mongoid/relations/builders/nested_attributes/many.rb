# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module NestedAttributes #:nodoc:
        class Many < NestedBuilder

          # Builds the relation depending on the attributes and the options
          # passed to the macro.
          #
          # This attempts to perform 3 operations, either one of an update of
          # the existing relation, a replacement of the relation with a new
          # document, or a removal of the relation.
          #
          # @example Build the nested attrs.
          #   many.build(person)
          #
          # @param [ Document ] parent The parent document of the relation.
          #
          # @return [ Array ] The attributes.
          def build(parent)
            @existing = parent.send(metadata.name)
            if over_limit?(attributes)
              raise Errors::TooManyNestedAttributeRecords.new(existing, options[:limit])
            end
            attributes.each do |attrs|
              if attrs.respond_to?(:with_indifferent_access)
                process(parent, attrs)
              else
                process(parent, attrs[1])
              end
            end
          end

          # Create the new builder for nested attributes on one-to-many
          # relations.
          #
          # @example Initialize the builder.
          #   One.new(metadata, attributes, options)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Hash ] attributes The attributes hash to attempt to set.
          # @param [ Hash ] options The options defined.
          def initialize(metadata, attributes, options = {})
            if attributes.respond_to?(:with_indifferent_access)
              @attributes = attributes.with_indifferent_access.sort do |a, b|
                a[0].to_i <=> b[0].to_i
              end
            else
              @attributes = attributes
            end
            @metadata = metadata
            @options = options
          end

          private

          # Can the existing relation potentially be deleted?
          #
          # @example Is the document destroyable?
          #   destroyable?({ :_destroy => "1" })
          #
          # @parma [ Hash ] attributes The attributes to pull the flag from.
          #
          # @return [ true, false ] If the relation can potentially be deleted.
          def destroyable?(attributes)
            destroy = attributes.delete(:_destroy)
            [ 1, "1", true, "true" ].include?(destroy) && allow_destroy?
          end

          # Are the supplied attributes of greater number than the supplied
          # limit?
          #
          # @example Are we over the set limit?
          #   builder.over_limit?({ "street" => "Bond" })
          #
          # @param [ Hash ] attributes The attributes being set.
          #
          # @return [ true, false ] If the attributes exceed the limit.
          def over_limit?(attributes)
            limit = options[:limit]
            limit ? attributes.size > limit : false
          end

          # Process each set of attributes one at a time for each potential
          # new, existing, or ignored document.
          #
          # @example Process the attributes
          #   builder.process({ "id" => 1, "street" => "Bond" })
          #
          # @param [ Hash ] attrs The single document attributes to process.
          def process(parent, attrs)
            return if reject?(parent, attrs)
            if id = attrs["id"] || attrs["_id"]
              doc = existing.find(convert_id(id))
              if destroyable?(attrs)
                existing.delete(doc)
                doc.destroy unless doc.embedded?
              else
                metadata.embedded? ? doc.attributes = attrs : doc.update_attributes(attrs)
              end
            else
              existing.push(Factory.build(metadata.klass, attrs)) unless destroyable?(attrs)
            end
          end
        end
      end
    end
  end
end
