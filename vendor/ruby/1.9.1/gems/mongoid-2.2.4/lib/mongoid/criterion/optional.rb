# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Optional

      # Adds fields to be sorted in ascending order. Will add them in the order
      # they were passed into the method.
      #
      # @example Sort in ascending order.
      #   criteria.ascending(:title, :dob)
      #   criteria.asc(:title, :dob)
      #
      # @param [ Array<Symbol> ] fields The fields to sort on.
      #
      # @return [ Criteria ] The cloned criteria.
      def ascending(*fields)
        clone.tap do |crit|
          crit.options[:sort] = [] unless options[:sort] || fields.first.nil?
          fields.flatten.each { |field| merge_options(crit.options[:sort], [ field, :asc ]) }
        end
      end
      alias :asc :ascending

      # Tells the criteria that the cursor that gets returned needs to be
      # cached. This is so multiple iterations don't hit the database multiple
      # times, however this is not advisable when working with large data sets
      # as the entire results will get stored in memory.
      #
      # @example Flag the criteria as cached.
      #   criteria.cache
      #
      # @return [ Criteria ] The cloned criteria.
      def cache
        clone.tap { |crit| crit.options.merge!(:cache => true) }
      end

      # Will return true if the cache option has been set.
      #
      # @example Is the criteria cached?
      #   criteria.cached?
      #
      # @return [ true, false ] If the criteria is flagged as cached.
      def cached?
        options[:cache] == true
      end

      # Adds fields to be sorted in descending order. Will add them in the order
      # they were passed into the method.
      #
      # @example Sort the criteria in descending order.
      #   criteria.descending(:title, :dob)
      #   criteria.desc(:title, :dob)
      #
      # @param [ Array<Symbol> ] fields The fields to sort on.
      #
      # @return [ Criteria ] The cloned criteria.
      def descending(*fields)
        clone.tap do |crit|
          crit.options[:sort] = [] unless options[:sort] || fields.first.nil?
          fields.flatten.each { |field| merge_options(crit.options[:sort], [ field, :desc ]) }
        end
      end
      alias :desc :descending

      # Adds a criterion to the +Criteria+ that specifies additional options
      # to be passed to the Ruby driver, in the exact format for the driver.
      #
      # @example Add extra params to the criteria.
      #   criteria.extras(:limit => 20, :skip => 40)
      #
      # @param [ Hash ] extras The extra driver options.
      #
      # @return [ Criteria ] The cloned criteria.
      def extras(extras)
        clone.tap do |crit|
          crit.options.merge!(extras)
        end
      end

      # Adds a criterion to the +Criteria+ that specifies an id that must be matched.
      #
      # @example Add a single id criteria.
      #   criteria.for_ids("4ab2bc4b8ad548971900005c")
      #
      # @example Add multiple id criteria.
      #   criteria.for_ids(["4ab2bc4b8ad548971900005c", "4c454e7ebf4b98032d000001"])
      #
      # @param [ Array ] ids: A single id or an array of ids.
      #
      # @return [ Criteria ] The cloned criteria.
      def for_ids(*ids)
        ids.flatten!
        if ids.size > 1
          any_in(
            :_id => ::BSON::ObjectId.convert(klass, ids)
          )
        else
          clone.tap do |crit|
            crit.selector[:_id] =
              ::BSON::ObjectId.convert(klass, ids.first)
          end
        end
      end

      # Adds a criterion to the +Criteria+ that specifies the maximum number of
      # results to return. This is mostly used in conjunction with skip()
      # to handle paginated results.
      #
      # @example Limit the result set size.
      #   criteria.limit(100)
      #
      # @param [ Integer ] value The max number of results.
      #
      # @return [ Criteria ] The cloned criteria.
      def limit(value = 20)
        clone.tap { |crit| crit.options[:limit] = value }
      end

      # Returns the offset option. If a per_page option is in the list then it
      # will replace it with a skip parameter and return the same value. Defaults
      # to 20 if nothing was provided.
      #
      # @example Get the offset.
      #   criteria.offset(10)
      #
      # @return [ Integer ] The number of documents to skip.
      def offset(*args)
        args.size > 0 ? skip(args.first) : options[:skip]
      end

      # Adds a criterion to the +Criteria+ that specifies the sort order of
      # the returned documents in the database. Similar to a SQL "ORDER BY".
      #
      # @example Order by specific fields.
      #   criteria.order_by([[:field1, :asc], [:field2, :desc]])
      #
      # @param [ Array ] params: An +Array+ of [field, direction] sorting pairs.
      #
      # @return [ Criteria ] The cloned criteria.
      def order_by(*args)
        clone.tap do |crit|
          arguments = args.size == 1 ? args.first : args
          crit.options[:sort] = [] unless options[:sort] || args.first.nil?
          if arguments.is_a?(Array)
            #[:name, :asc]
            if arguments.size == 2 && (arguments.first.is_a?(Symbol) || arguments.first.is_a?(String))
              build_order_options(arguments, crit)
            else
              arguments.each { |argument| build_order_options(argument, crit) }
            end
          else
            build_order_options(arguments, crit)
          end
        end
      end
      alias :order :order_by

      # Adds a criterion to the +Criteria+ that specifies how many results to skip
      # when returning Documents. This is mostly used in conjunction with
      # limit() to handle paginated results, and is similar to the
      # traditional "offset" parameter.
      #
      # @example Skip a specified number of documents.
      #   criteria.skip(20)
      #
      # @param [ Integer ] value The number of results to skip.
      #
      # @return [ Criteria ] The cloned criteria.
      def skip(value = 0)
        clone.tap { |crit| crit.options[:skip] = value }
      end

      # Adds a criterion to the +Criteria+ that specifies a type or an Array of
      # types that must be matched.
      #
      # @example Match only specific models.
      #   criteria.type('Browser')
      #   criteria.type(['Firefox', 'Browser'])
      #
      # @param [ Array<String> ] types The types to match against.
      #
      # @return [ Criteria ] The cloned criteria.
      def type(types)
        types = [types] unless types.is_a?(Array)
        any_in(:_type => types)
      end

      private

      # Build ordering options from given arguments on given criteria
      #
      # @example build order options
      #   criteria.build_order_options(:name.asc, criteria)
      #
      #
      # @param [ <Hash>, <Array>, <Complex> ] argument to build criteria from
      # @param [ Criterion ] criterion to change
      def build_order_options(arguments, crit)
        case arguments
        when Hash
          if arguments.size > 1
            raise ArgumentError, "Please don't use hash to define multiple orders " +
                "due to the fact that hash doesn't have order this may cause unpredictable results"
          end
          arguments.each_pair do |field, direction|
            merge_options(crit.options[:sort], [ field, direction ])
          end
        when Array
          merge_options(crit.options[:sort],arguments)
        when Complex
          merge_options(crit.options[:sort], [ arguments.key, arguments.operator.to_sym ])
        end
      end

      # Merge options for order_by criterion
      # Allow only one order direction for same field
      #
      # @example Merge ordering options
      #   criteria.merge_options([[:title, :asc], [:created_at, :asc]], [:title, :desc])
      #
      #
      # @param [ Array<Array> ] Existing options
      # @param [ Array ] New option for merge.
      #
      # @since 2.1.0
      def merge_options(options, new_option)
        old_option = options.assoc(new_option.first)

        if old_option
          options[options.index(old_option)] = new_option.flatten
        else
          options << new_option.flatten
        end
      end
    end
  end
end
