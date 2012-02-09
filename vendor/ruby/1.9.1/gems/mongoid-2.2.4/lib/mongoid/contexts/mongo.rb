# encoding: utf-8
module Mongoid #:nodoc:
  module Contexts #:nodoc:
    class Mongo
      attr_accessor :criteria

      delegate :cached?, :klass, :options, :field_list, :selector, :to => :criteria
      delegate :collection, :to => :klass

      # Perform an add to set on the matching documents.
      #
      # @example Add to set on all matching.
      #   Person.where(:name => "Alex").add_to_set(:aliases, "value")
      #
      # @param [ String ] field The field to add to.
      # @param [ Object ] value The value to add.
      #
      # @return [ Object ] The update value.
      #
      # @since 2.1.0
      def add_to_set(field, value)
        klass.collection.update(
          selector,
          { "$addToSet" => { field => value } },
          :multi => true
        )
      end

      # Aggregate the context. This will take the internally built selector and options
      # and pass them on to the Ruby driver's +group()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned it will provided a grouping of keys with counts.
      #
      # @example Aggreate the context.
      #   context.aggregate
      #
      # @return [ Hash ] A +Hash+ with field values as keys, counts as values
      def aggregate
        klass.collection.group(
          :key => field_list,
          :cond => selector,
          :initial => { :count => 0 },
          :reduce => Javascript.aggregate
        )
      end

      # Get the average value for the supplied field.
      #
      # This will take the internally built selector and options
      # and pass them on to the Ruby driver's +group()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned it will provided a grouping of keys with averages.
      #
      # @example Get the average for a field.
      #   context.avg(:age)
      #
      # @param [ Symbol ] field The field to get the average for.
      #
      # @return [ Numeric ] A numeric value that is the average.
      def avg(field)
        total = sum(field)
        total ? (total / count) : nil
      end

      # Determine if the context is empty or blank given the criteria. Will
      # perform a quick has_one asking only for the id.
      #
      # @example Is the context empty?
      #   context.blank?a
      #
      # @return [ true, false ] True if blank.
      def blank?
        klass.collection.find_one(selector, { :fields => [ :_id ] }).nil?
      end
      alias :empty? :blank?

      # Get the count of matching documents in the database for the context.
      #
      # @example Get the count without skip and limit taken into consideration.
      #   context.count
      #
      # @example Get the count with skip and limit applied.
      #   context.count(true)
      #
      # @param [Boolean] extras True to inclued previous skip/limit
      #   statements in the count; false to ignore them. Defaults to `false`.
      #
      # @return [ Integer ] The count of documents.
      def count(extras = false)
        if cached?
          @count ||= collection.find(selector, process_options).count(extras)
        else
          collection.find(selector, process_options).count(extras)
        end
      end
      alias :size :count
      alias :length :count

      # Delete all the documents in the database matching the selector.
      #
      # @example Delete the documents.
      #   context.delete_all
      #
      # @return [ Integer ] The number of documents deleted.
      #
      # @since 2.0.0.rc.1
      def delete_all
        klass.delete_all(:conditions => selector)
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
        klass.destroy_all(:conditions => selector)
      end
      alias :destroy :destroy_all

      # Gets an array of distinct values for the supplied field across the
      # entire collection or the susbset given the criteria.
      #
      # @example Get the distinct values.
      #   context.distinct(:title)
      #
      # @param [ Symbol ] field The field to get the values for.
      #
      # @return [ Array<Object> ] The distinct values for the field.
      def distinct(field)
        klass.collection.distinct(field, selector)
      end

      # Execute the context. This will take the selector and options
      # and pass them on to the Ruby driver's +find()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned new documents of the type of class provided will be instantiated.
      #
      # @example Execute the criteria on the context.
      #   context.execute
      #
      # @return [ Cursor ] An enumerable +Cursor+ of results.
      def execute
        criteria.inclusions.reject! do |metadata|
          metadata.eager_load(criteria)
        end
        klass.collection.find(selector, process_options) || []
      end

      # Return the first result for the +Context+.
      #
      # @example Get the first document.
      #   context.one
      #
      # @return [ Document ] The first document in the collection.
      def first
        opts = process_options
        sorting = opts[:sort] ||= []
        sorting << [:_id, :asc]
        attributes = klass.collection.find_one(selector, opts)
        attributes ? Mongoid::Factory.from_db(klass, attributes) : nil
      end
      alias :one :first

      # Groups the context. This will take the internally built selector and options
      # and pass them on to the Ruby driver's +group()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned it will provided a grouping of keys with objects.
      #
      # @example Get the criteria as a group.
      #   context.group
      #
      # @return [ Hash ] Hash with field values as keys, arrays of documents as values.
      def group
        klass.collection.group(
          :key => field_list,
          :cond => selector,
          :initial => { :group => [] },
          :reduce => Javascript.group
        ).collect do |docs|
          docs["group"] = docs["group"].collect do |attrs|
            Mongoid::Factory.from_db(klass, attrs)
          end
          docs
        end
      end

      # Create the new mongo context. This will execute the queries given the
      # selector and options against the database.
      #
      # @example Create a new context.
      #   Mongoid::Contexts::Mongo.new(criteria)
      #
      # @param [ Criteria ] criteria The criteria to create with.
      def initialize(criteria)
        @criteria = criteria
        if klass.hereditary? && !criteria.selector.keys.include?(:_type)
          @criteria = criteria.in(:_type => criteria.klass._types)
        end
        @criteria.cache if klass.cached?
      end

      # Iterate over each +Document+ in the results. This can take an optional
      # block to pass to each argument in the results.
      #
      # @example Iterate over the results.
      #   context.iterate { |doc| p doc }
      def iterate(&block)
        return caching(&block) if cached?
        if block_given?
          execute.each { |doc| yield doc }
        end
      end

      # Return the last result for the +Context+. Essentially does a find_one on
      # the collection with the sorting reversed. If no sorting parameters have
      # been provided it will default to ids.
      #
      # @example Get the last document.
      #   context.last
      #
      # @return [ Document ] The last document in the collection.
      def last
        opts = process_options
        sorting = opts[:sort] ||= []
        sorting << [:_id, :asc]
        opts[:sort] = sorting.map{ |option| [ option[0], option[1].invert ] }.uniq
        attributes = klass.collection.find_one(selector, opts)
        attributes ? Mongoid::Factory.from_db(klass, attributes) : nil
      end

      # Return the max value for a field.
      #
      # This will take the internally built selector and options
      # and pass them on to the Ruby driver's +group()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned it will provided a grouping of keys with sums.
      #
      # @example Get the max value.
      #   context.max(:age)
      #
      # @param [ Symbol ] field The field to get the max for.
      #
      # @return [ Numeric ] A numeric max value.
      def max(field)
        grouped(:max, field.to_s, Javascript.max)
      end

      # Return the min value for a field.
      #
      # This will take the internally built selector and options
      # and pass them on to the Ruby driver's +group()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned it will provided a grouping of keys with sums.
      #
      # @example Get the min value.
      #   context.min(:age)
      #
      # @param [ Symbol ] field The field to get the min for.
      #
      # @return [ Numeric ] A numeric minimum value.
      def min(field)
        grouped(:min, field.to_s, Javascript.min)
      end

      # Perform a pull on the matching documents.
      #
      # @example Pull on all matching.
      #   Person.where(:name => "Alex").pull(:aliases, "value")
      #
      # @param [ String ] field The field to pull from.
      # @param [ Object ] value The value to pull.
      #
      # @return [ Object ] The update value.
      #
      # @since 2.1.0
      def pull(field, value)
        klass.collection.update(
          selector,
          { "$pull" => { field => value } },
          :multi => true
        )
      end

      # Return the first result for the +Context+ and skip it
      # for successive calls.
      #
      # @example Get the first document and shift.
      #   context.shift
      #
      # @return [ Document ] The first document in the collection.
      def shift
        first.tap { criteria.skip((options[:skip] || 0) + 1) }
      end

      # Sum the context.
      #
      # This will take the internally built selector and options
      # and pass them on to the Ruby driver's +group()+ method on the collection. The
      # collection itself will be retrieved from the class provided, and once the
      # query has returned it will provided a grouping of keys with sums.
      #
      # @example Get the sum for a field.
      #   context.sum(:age)
      #
      # @param [ Symbol ] field The field who's values to sum.
      #
      # @return [ Numeric ] A numeric value that is the sum.
      def sum(field)
        grouped(:sum, field.to_s, Javascript.sum)
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
      # @since 2.0.0.rc.4
      def update_all(attributes = {})
        klass.collection.update(
          selector,
          { "$set" => attributes },
          Safety.merge_safety_options(:multi => true)
        ).tap do
          Threaded.clear_safety_options!
        end
      end
      alias :update :update_all

      protected

      # Iterate over each +Document+ in the results and cache the collection.
      #
      # @example Execute with caching.
      #   context.caching
      def caching(&block)
        if defined? @collection
          @collection.each(&block)
        else
          @collection = []
          execute.each do |doc|
            @collection << doc
            yield doc if block_given?
          end
        end
      end

      # Common functionality for grouping operations. Currently used by min, max
      # and sum. Will gsub the field name in the supplied reduce function.
      #
      # @example Execute the group function.
      #   context.group(0, :avg, "")
      #
      # @param [ Object ] start The value to start the map/reduce with.
      # @param [ String ] field The field to aggregate.
      # @param [ String ] reduce The reduce JS function.
      #
      # @return [ Numeric ] A numeric result.
      def grouped(start, field, reduce)
        collection = klass.collection.group(
          :cond => selector,
          :initial => { start => "start" },
          :reduce => reduce.gsub("[field]", field)
        )
        value = collection.empty? ? nil : collection.first[start.to_s]
        value ? (value.nan? ? nil : value) : value
      end

      # Filters the field list. If no fields have been supplied, then it will be
      # empty. If fields have been defined then _type will be included as well.
      #
      # @example Process the field list.
      #   context.process_options
      #
      # @return [ Hash ] The options.
      def process_options
        fields = options[:fields]
        if fields && fields.size > 0 && !fields.include?(:_type)
          if fields.kind_of?(Hash)
            fields[:_type] = 1 if fields.first.last != 0 # Not excluding
          else
            fields << :type
          end
          options[:fields] = fields
        end
        options.dup
      end
    end
  end
end
