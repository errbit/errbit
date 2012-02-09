# encoding: utf-8
require 'mongoid/contexts/enumerable/sort'

module Mongoid #:nodoc:
  module Contexts #:nodoc:
    class Enumerable
      include Relations::Embedded::Atomic

      attr_accessor :collection, :criteria

      delegate :blank?, :empty?, :first, :last, :to => :execute
      delegate :klass, :documents, :options, :field_list, :selector, :to => :criteria

      # Return aggregation counts of the grouped documents. This will count by
      # the first field provided in the fields array.
      #
      # @example Aggregate on a field.
      #   person.addresses.only(:street).aggregate
      #
      # @return [ Hash ] Field values as keys, count as values
      def aggregate
        {}.tap do |counts|
          group.each_pair { |key, value| counts[key] = value.size }
        end
      end

      # Get the average value for the supplied field.
      #
      # @example Get the average.
      #   context.avg(:age)
      #
      # @return [ Numeric ] A numeric value that is the average.
      def avg(field)
        total = sum(field)
        total ? (total.to_f / count) : nil
      end

      # Gets the number of documents in the array. Delegates to size.
      #
      # @example Get the count.
      #   context.count
      #
      # @return [ Integer ] The count of documents.
      def count
        @count ||= execute.size
      end
      alias :length :count
      alias :size :count

      # Delete all the documents in the database matching the selector.
      #
      # @example Delete the documents.
      #   context.delete_all
      #
      # @return [ Integer ] The number of documents deleted.
      #
      # @since 2.0.0.rc.1
      def delete_all
        atomically(:$pull) do
          set_collection
          count.tap do
            filter.each { |doc| doc.delete }
          end
        end
      end
      alias :delete :delete_all

      # Destroy all the documents in the database matching the selector.
      #
      # @example Destroy the documents.
      #   context.destroy_all
      #
      # @return [ Integer ] The number of documents destroyed.
      #
      # @since 2.0.0.rc.1
      def destroy_all
        atomically(:$pull) do
          set_collection
          count.tap do
            filter.each { |doc| doc.destroy }
          end
        end
      end
      alias :destroy :destroy_all

      # Gets an array of distinct values for the supplied field across the
      # entire array or the susbset given the criteria.
      #
      # @example Get the list of distinct values.
      #   context.distinct(:title)
      #
      # @return [ Array<String> ] The distinct values.
      def distinct(field)
        execute.collect { |doc| doc.send(field) }.uniq
      end

      # Enumerable implementation of execute. Returns matching documents for
      # the selector, and adds options if supplied.
      #
      # @example Execute the context.
      #   context.execute
      #
      # @return [ Array<Document> ] Documents that matched the selector.
      def execute
        limit(sort(filter)) || []
      end

      # Groups the documents by the first field supplied in the field options.
      #
      # @example Group the context.
      #   context.group
      #
      # @return [ Hash ] Field values as keys, arrays of documents as values.
      def group
        field = field_list.first
        execute.group_by { |doc| doc.send(field) }
      end

      # Create the new enumerable context. This will need the selector and
      # options from a +Criteria+ and a documents array that is the underlying
      # array of embedded documents from a has many association.
      #
      # @example Create a new context.
      #   Mongoid::Contexts::Enumerable.new(criteria)
      #
      # @param [ Criteria ] criteria The criteria for the context.
      def initialize(criteria)
        @criteria = criteria
      end

      # Iterate over each +Document+ in the results. This can take an optional
      # block to pass to each argument in the results.
      #
      # @example Iterate over the documents.
      #   context.iterate { |doc| p doc }
      def iterate(&block)
        execute.each(&block)
      end

      # Get the largest value for the field in all the documents.
      #
      # @example Get the max value.
      #   context.max(:age)
      #
      # @return [ Numeric ] The numerical largest value.
      def max(field)
        determine(field, :>=)
      end

      # Get the smallest value for the field in all the documents.
      #
      # @example Get the minimum value.
      #   context.min(:age)
      #
      # @return [ Numeric ] The numerical smallest value.
      def min(field)
        determine(field, :<=)
      end

      # Get one document.
      #
      # @example Get one document.
      #   context.one
      #
      # @return [ Document ] The first document in the array.
      alias :one :first

      # Get one document and tell the criteria to skip this record on
      # successive calls.
      #
      # @example Shift the documents.
      #   context.shift
      #
      # @return [ Document ] The first document in the array.
      def shift
        first.tap do |document|
          self.criteria = criteria.skip((options[:skip] || 0) + 1)
        end
      end

      # Get the sum of the field values for all the documents.
      #
      # @example Get the sum of the field.
      #   context.sum(:cost)
      #
      # @return [ Numeric ] The numerical sum of all the document field values.
      def sum(field)
        sum = execute.inject(nil) do |memo, doc|
          value = doc.send(field) || 0
          memo ? memo += value : value
        end
      end

      # Very basic update that will perform a simple atomic $set of the
      # attributes provided in the hash. Can be expanded to later for more
      # robust functionality.
      #
      # @example Update all matching documents.
      #   context.update_all(:title => "Sir")
      #
      # @param [ Hash ] attributes The sets to perform.
      #
      # @since 2.0.0.rc.6
      def update_all(attributes = nil)
        iterate do |doc|
          doc.update_attributes(attributes || {})
        end
      end
      alias :update :update_all

      protected

      # Filters the documents against the criteria's selector
      #
      # @example Filter the documents.
      #   context.filter
      #
      # @return [ Array ] The documents filtered.
      def filter
        documents.select { |document| document.matches?(selector) }
      end

      # If the field exists, perform the comparison and set if true.
      #
      # @example Compare.
      #   context.determine
      #
      # @return [ Array<Document> ] The matching documents.
      def determine(field, operator)
        matching = documents.inject(nil) do |memo, doc|
          value = doc.send(field) || 0
          (memo && memo.send(operator, value)) ? memo : value
        end
      end

      # Limits the result set if skip and limit options.
      #
      # @example Limit the results.
      #   context.limit(documents)
      #
      # @return [ Array<Document> ] The limited documents.
      def limit(documents)
        skip, limit = options[:skip], options[:limit]
        if skip && limit
          return documents.slice(skip, limit)
        elsif limit
          return documents.first(limit)
        elsif skip
          return documents.slice(skip..-1)
        end
        documents
      end

      def root
        @root ||= documents.first.try(:_root)
      end

      def root_class
        @root_class ||= root ? root.class : nil
      end

      # Set the collection to the collection of the root document.
      #
      # @example Set the collection.
      #   context.set_collection
      #
      # @return [ Collection ] The root collection.
      def set_collection
        @collection = root.collection if root && !root.embedded?
      end

      # Sorts the result set if sort options have been set.
      #
      # @example Sort the documents.
      #   context.sort(documents)
      #
      # @return [ Array<Document> ] The sorted documents.
      def sort(documents)
        return documents if options[:sort].blank?
        documents.sort_by do |document|
          options[:sort].map do |key, direction|
            Sort.new(document.read_attribute(key), direction)
          end
        end
      end
    end
  end
end
