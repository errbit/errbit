# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:

    # This module contains criteria behaviour for exclusion of values.
    module Exclusion

      # Adds a criterion to the +Criteria+ that specifies values that are not
      # allowed to match any document in the database. The MongoDB
      # conditional operator that will be used is "$ne".
      #
      # @example Match documents without these values.
      #   criteria.excludes(:field => "value1")
      #   criteria.excludes(:field1 => "value1", :field2 => "value1")
      #
      # @param [ Hash ] attributes: A +Hash+ where the key is the field
      #   name and the value is a value that must not be equal to the
      #   corresponding field value in the database.
      #
      # @return [ Criteria ] A newly cloned copy.
      def excludes(attributes = {})
        mongo_id = attributes.delete(:id)
        attributes = attributes.merge(:_id => mongo_id) if mongo_id
        update_selector(attributes, "$ne")
      end

      # Used when wanting to set the fields options directly using a hash
      # instead of going through only or without.
      #
      # @example Set the limited fields.
      #   criteria.fields(:field => 1)
      #
      # @param [ Hash ] attributes The field options.
      #
      # @return [ Criteria ] A newly cloned copy.
      #
      # @since 2.0.2
      def fields(attributes = nil)
        clone.tap { |crit| crit.options[:fields] = attributes || {} }
      end

      # Adds a criterion to the +Criteria+ that specifies values where none
      # should match in order to return results. This is similar to an SQL
      # "NOT IN" clause. The MongoDB conditional operator that will be
      # used is "$nin".
      #
      # @example Match documents with values not in the provided.
      #   criteria.not_in(:field => ["value1", "value2"])
      #   criteria.not_in(:field1 => ["value1", "value2"], :field2 => ["value1"])
      #
      # @param [ Hash ] attributes A +Hash+ where the key is the field name
      #   and the value is an +Array+ of values that none can match.
      #
      # @return [ Criteria ] A newly cloned copy.
      def not_in(attributes)
        update_selector(attributes, "$nin")
      end

      # Adds a criterion to the +Criteria+ that specifies the fields that will
      # get returned from the Document. Used mainly for list views that do not
      # require all fields to be present. This is similar to SQL "SELECT" values.
      #
      # @example Limit the fields to only the specified.
      #   criteria.only(:field1, :field2, :field3)
      #
      # @note #only and #without cannot be used together.
      #
      # @param [ Array<Symbol> ] args A list of field names to limit to.
      #
      # @return [ Criteria ] A newly cloned copy.
      def only(*args)
        clone.tap do |crit|
          if args.any?
            crit.options[:fields] = {:_type => 1}
            crit.field_list = args.flatten
            crit.field_list.each do |f|
              crit.options[:fields][f] = 1
            end
          end
        end
      end

      # Adds a criterion to the +Criteria+ that specifies the fields that will
      # not get returned by the document.
      #
      # @example Filter out specific fields.
      #   criteria.without(:field2, :field2)
      #
      # @note #only and #without cannot be used together.
      #
      # @param [ Array<Symbol> args A list of fields to exclude.
      #
      # @return [ Criteria ] A newly cloned copy.
      #
      # @since 2.0.0
      def without(*args)
        clone.tap do |crit|
          if args.any?
            crit.options[:fields] = {}
            args.flatten.each do |f|
              crit.options[:fields][f] = 0
            end
          end
        end
      end
    end
  end
end
