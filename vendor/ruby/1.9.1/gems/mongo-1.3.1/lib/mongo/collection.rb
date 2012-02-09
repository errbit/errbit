# encoding: UTF-8

# --
# Copyright (C) 2008-2011 10gen Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mongo

  # A named collection of documents in a database.
  class Collection

    attr_reader :db, :name, :pk_factory, :hint, :safe

    # Initialize a collection object.
    #
    # @param [String, Symbol] name the name of the collection.
    # @param [DB] db a MongoDB database instance.
    #
    # @option opts [:create_pk] :pk (BSON::ObjectId) A primary key factory to use
    #   other than the default BSON::ObjectId.
    #
    # @option opts [Boolean, Hash] :safe (false) Set the default safe-mode options
    #   for insert, update, and remove method called on this Collection instance. If no
    #   value is provided, the default value set on this instance's DB will be used. This
    #   default can be overridden for any invocation of insert, update, or remove.
    #
    # @raise [InvalidNSName]
    #   if collection name is empty, contains '$', or starts or ends with '.'
    #
    # @raise [TypeError]
    #   if collection name is not a string or symbol
    #
    # @return [Collection]
    #
    # @core collections constructor_details
    def initialize(name, db, opts={})
      if db.is_a?(String) && name.is_a?(Mongo::DB)
        warn "Warning: the order of parameters to initialize a collection have changed. " +
             "Please specify the collection name first, followed by the db."
        db, name = name, db
      end

      case name
      when Symbol, String
      else
        raise TypeError, "new_name must be a string or symbol"
      end

      name = name.to_s

      if name.empty? or name.include? ".."
        raise Mongo::InvalidNSName, "collection names cannot be empty"
      end
      if name.include? "$"
        raise Mongo::InvalidNSName, "collection names must not contain '$'" unless name =~ /((^\$cmd)|(oplog\.\$main))/
      end
      if name.match(/^\./) or name.match(/\.$/)
        raise Mongo::InvalidNSName, "collection names must not start or end with '.'"
      end

      if opts.respond_to?(:create_pk) || !opts.is_a?(Hash)
        warn "The method for specifying a primary key factory on a Collection has changed.\n" +
          "Please specify it as an option (e.g., :pk => PkFactory)."
        pk_factory = opts
      else
        pk_factory = nil
      end

      @db, @name  = db, name
      @connection = @db.connection
      @cache_time = @db.cache_time
      @cache = Hash.new(0)
      unless pk_factory
        @safe = opts.fetch(:safe, @db.safe)
      end
      @pk_factory = pk_factory || opts[:pk] || BSON::ObjectId
      @hint = nil
    end

    # Return a sub-collection of this collection by name. If 'users' is a collection, then
    # 'users.comments' is a sub-collection of users.
    #
    # @param [String, Symbol] name
    #   the collection to return
    #
    # @raise [Mongo::InvalidNSName]
    #   if passed an invalid collection name
    #
    # @return [Collection]
    #   the specified sub-collection
    def [](name)
      name = "#{self.name}.#{name}"
      return Collection.new(name, db) if !db.strict? ||
        db.collection_names.include?(name.to_s)
      raise "Collection #{name} doesn't exist. Currently in strict mode."
    end

    # Set a hint field for query optimizer. Hint may be a single field
    # name, array of field names, or a hash (preferably an [OrderedHash]).
    # If using MongoDB > 1.1, you probably don't ever need to set a hint.
    #
    # @param [String, Array, OrderedHash] hint a single field, an array of
    #   fields, or a hash specifying fields
    def hint=(hint=nil)
      @hint = normalize_hint_fields(hint)
      self
    end

    # Query the database.
    #
    # The +selector+ argument is a prototype document that all results must
    # match. For example:
    #
    #   collection.find({"hello" => "world"})
    #
    # only matches documents that have a key "hello" with value "world".
    # Matches can have other keys *in addition* to "hello".
    #
    # If given an optional block +find+ will yield a Cursor to that block,
    # close the cursor, and then return nil. This guarantees that partially
    # evaluated cursors will be closed. If given no block +find+ returns a
    # cursor.
    #
    # @param [Hash] selector
    #   a document specifying elements which must be present for a
    #   document to be included in the result set. Note that in rare cases,
    #   (e.g., with $near queries), the order of keys will matter. To preserve
    #   key order on a selector, use an instance of BSON::OrderedHash (only applies
    #   to Ruby 1.8).
    #
    # @option opts [Array, Hash] :fields field names that should be returned in the result
    #   set ("_id" will be included unless explicity excluded). By limiting results to a certain subset of fields,
    #   you can cut down on network traffic and decoding time. If using a Hash, keys should be field
    #   names and values should be either 1 or 0, depending on whether you want to include or exclude
    #   the given field.
    # @option opts [Integer] :skip number of documents to skip from the beginning of the result set
    # @option opts [Integer] :limit maximum number of documents to return
    # @option opts [Array]   :sort an array of [key, direction] pairs to sort by. Direction should
    #   be specified as Mongo::ASCENDING (or :ascending / :asc) or Mongo::DESCENDING (or :descending / :desc)
    # @option opts [String, Array, OrderedHash] :hint hint for query optimizer, usually not necessary if
    #   using MongoDB > 1.1
    # @option opts [Boolean] :snapshot (false) if true, snapshot mode will be used for this query.
    #   Snapshot mode assures no duplicates are returned, or objects missed, which were preset at both the start and
    #   end of the query's execution.
    #   For details see http://www.mongodb.org/display/DOCS/How+to+do+Snapshotting+in+the+Mongo+Database
    # @option opts [Boolean] :batch_size (100) the number of documents to returned by the database per
    #   GETMORE operation. A value of 0 will let the database server decide how many results to returns.
    #   This option can be ignored for most use cases.
    # @option opts [Boolean] :timeout (true) when +true+, the returned cursor will be subject to
    #   the normal cursor timeout behavior of the mongod process. When +false+, the returned cursor will
    #   never timeout. Note that disabling timeout will only work when #find is invoked with a block.
    #   This is to prevent any inadvertant failure to close the cursor, as the cursor is explicitly
    #   closed when block code finishes.
    # @option opts [Integer] :max_scan (nil) Limit the number of items to scan on both collection scans and indexed queries..
    # @option opts [Boolean] :show_disk_loc (false) Return the disk location of each query result (for debugging).
    # @option opts [Boolean] :return_key (false) Return the index key used to obtain the result (for debugging).
    # @option opts [Block] :transformer (nil) a block for tranforming returned documents.
    #   This is normally used by object mappers to convert each returned document to an instance of a class.
    #
    # @raise [ArgumentError]
    #   if timeout is set to false and find is not invoked in a block
    #
    # @raise [RuntimeError]
    #   if given unknown options
    #
    # @core find find-instance_method
    def find(selector={}, opts={})
      opts   = opts.dup
      fields = opts.delete(:fields)
      fields = ["_id"] if fields && fields.empty?
      skip   = opts.delete(:skip) || skip || 0
      limit  = opts.delete(:limit) || 0
      sort   = opts.delete(:sort)
      hint   = opts.delete(:hint)
      snapshot   = opts.delete(:snapshot)
      batch_size = opts.delete(:batch_size)
      timeout    = (opts.delete(:timeout) == false) ? false : true
      transformer = opts.delete(:transformer)

      if timeout == false && !block_given?
        raise ArgumentError, "Collection#find must be invoked with a block when timeout is disabled."
      end

      if hint
        hint = normalize_hint_fields(hint)
      else
        hint = @hint        # assumed to be normalized already
      end

      raise RuntimeError, "Unknown options [#{opts.inspect}]" unless opts.empty?

      cursor = Cursor.new(self, {
        :selector    => selector, 
        :fields      => fields, 
        :skip        => skip, 
        :limit       => limit,
        :order       => sort, 
        :hint        => hint, 
        :snapshot    => snapshot, 
        :timeout     => timeout, 
        :batch_size  => batch_size,
        :transformer => transformer,
      })

      if block_given?
        yield cursor
        cursor.close
        nil
      else
        cursor
      end
    end

    # Return a single object from the database.
    #
    # @return [OrderedHash, Nil]
    #   a single document or nil if no result is found.
    #
    # @param [Hash, ObjectId, Nil] spec_or_object_id a hash specifying elements 
    #   which must be present for a document to be included in the result set or an 
    #   instance of ObjectId to be used as the value for an _id query.
    #   If nil, an empty selector, {}, will be used.
    #
    # @option opts [Hash]
    #   any valid options that can be send to Collection#find
    #
    # @raise [TypeError]
    #   if the argument is of an improper type.
    def find_one(spec_or_object_id=nil, opts={})
      spec = case spec_or_object_id
             when nil
               {}
             when BSON::ObjectId
               {:_id => spec_or_object_id}
             when Hash
               spec_or_object_id
             else
               raise TypeError, "spec_or_object_id must be an instance of ObjectId or Hash, or nil"
             end
      find(spec, opts.merge(:limit => -1)).next_document
    end

    # Save a document to this collection.
    #
    # @param [Hash] doc
    #   the document to be saved. If the document already has an '_id' key,
    #   then an update (upsert) operation will be performed, and any existing
    #   document with that _id is overwritten. Otherwise an insert operation is performed.
    #
    # @return [ObjectId] the _id of the saved document.
    #
    # @option opts [Boolean, Hash] :safe (+false+)
    #   run the operation in safe mode, which run a getlasterror command on the
    #   database to report any assertion. In addition, a hash can be provided to
    #   run an fsync and/or wait for replication of the save (>= 1.5.1). See the options
    #   for DB#error.
    #
    # @raise [OperationFailure] when :safe mode fails.
    #
    # @see DB#remove for options that can be passed to :safe.
    def save(doc, opts={})
      if doc.has_key?(:_id) || doc.has_key?('_id')
        id = doc[:_id] || doc['_id']
        update({:_id => id}, doc, :upsert => true, :safe => opts.fetch(:safe, @safe))
        id
      else
        insert(doc, :safe => opts.fetch(:safe, @safe))
      end
    end

    # Insert one or more documents into the collection.
    #
    # @param [Hash, Array] doc_or_docs
    #   a document (as a hash) or array of documents to be inserted.
    #
    # @return [ObjectId, Array]
    #   The _id of the inserted document or a list of _ids of all inserted documents.
    #
    # @option opts [Boolean, Hash] :safe (+false+)
    #   run the operation in safe mode, which run a getlasterror command on the
    #   database to report any assertion. In addition, a hash can be provided to
    #   run an fsync and/or wait for replication of the insert (>= 1.5.1). Safe
    #   options provided here will override any safe options set on this collection,
    #   its database object, or the current connection. See the options on
    #   for DB#get_last_error.
    #
    # @see DB#remove for options that can be passed to :safe.
    #
    # @core insert insert-instance_method
    def insert(doc_or_docs, opts={})
      doc_or_docs = [doc_or_docs] unless doc_or_docs.is_a?(Array)
      doc_or_docs.collect! { |doc| @pk_factory.create_pk(doc) }
      safe = opts.fetch(:safe, @safe)
      result = insert_documents(doc_or_docs, @name, true, safe)
      result.size > 1 ? result : result.first
    end
    alias_method :<<, :insert

    # Remove all documents from this collection.
    #
    # @param [Hash] selector
    #   If specified, only matching documents will be removed.
    #
    # @option opts [Boolean, Hash] :safe (+false+)
    #   run the operation in safe mode, which will run a getlasterror command on the
    #   database to report any assertion. In addition, a hash can be provided to
    #   run an fsync and/or wait for replication of the remove (>= 1.5.1). Safe
    #   options provided here will override any safe options set on this collection,
    #   its database, or the current connection. See the options for DB#get_last_error for more details.
    #
    # @example remove all documents from the 'users' collection:
    #   users.remove
    #   users.remove({})
    #
    # @example remove only documents that have expired:
    #   users.remove({:expire => {"$lte" => Time.now}})
    #
    # @return [Hash, true] Returns a Hash containing the last error object if running in safe mode.
    #   Otherwise, returns true.
    #
    # @raise [Mongo::OperationFailure] an exception will be raised iff safe mode is enabled
    #   and the operation fails.
    #
    # @see DB#remove for options that can be passed to :safe.
    #
    # @core remove remove-instance_method
    def remove(selector={}, opts={})
      # Initial byte is 0.
      safe = opts.fetch(:safe, @safe)
      message = BSON::ByteBuffer.new("\0\0\0\0")
      BSON::BSON_RUBY.serialize_cstr(message, "#{@db.name}.#{@name}")
      message.put_int(0)
      message.put_binary(BSON::BSON_CODER.serialize(selector, false, true).to_s)

      @connection.instrument(:remove, :database => @db.name, :collection => @name, :selector => selector) do
        if safe
          @connection.send_message_with_safe_check(Mongo::Constants::OP_DELETE, message, @db.name, nil, safe)
        else
          @connection.send_message(Mongo::Constants::OP_DELETE, message)
          true
        end
      end
    end

    # Update one or more documents in this collection.
    #
    # @param [Hash] selector
    #   a hash specifying elements which must be present for a document to be updated. Note:
    #   the update command currently updates only the first document matching the
    #   given selector. If you want all matching documents to be updated, be sure
    #   to specify :multi => true.
    # @param [Hash] document
    #   a hash specifying the fields to be changed in the selected document,
    #   or (in the case of an upsert) the document to be inserted
    #
    # @option opts [Boolean] :upsert (+false+) if true, performs an upsert (update or insert)
    # @option opts [Boolean] :multi (+false+) update all documents matching the selector, as opposed to
    #   just the first matching document. Note: only works in MongoDB 1.1.3 or later.
    # @option opts [Boolean] :safe (+false+) 
    #   If true, check that the save succeeded. OperationFailure
    #   will be raised on an error. Note that a safe check requires an extra
    #   round-trip to the database. Safe options provided here will override any safe
    #   options set on this collection, its database object, or the current collection.
    #   See the options for DB#get_last_error for details.
    #
    # @return [Hash, true] Returns a Hash containing the last error object if running in safe mode.
    #   Otherwise, returns true.
    #
    # @core update update-instance_method
    def update(selector, document, opts={})
      # Initial byte is 0.
      safe = opts.fetch(:safe, @safe)
      message = BSON::ByteBuffer.new("\0\0\0\0")
      BSON::BSON_RUBY.serialize_cstr(message, "#{@db.name}.#{@name}")
      update_options  = 0
      update_options += 1 if opts[:upsert]
      update_options += 2 if opts[:multi]
      message.put_int(update_options)
      message.put_binary(BSON::BSON_CODER.serialize(selector, false, true).to_s)
      message.put_binary(BSON::BSON_CODER.serialize(document, false, true).to_s)

      @connection.instrument(:update, :database => @db.name, :collection => @name, :selector => selector, :document => document) do
        if safe
          @connection.send_message_with_safe_check(Mongo::Constants::OP_UPDATE, message, @db.name, nil, safe)
        else
          @connection.send_message(Mongo::Constants::OP_UPDATE, message)
        end
      end
    end

    # Create a new index.
    #
    # @param [String, Array] spec
    #   should be either a single field name or an array of
    #   [field name, direction] pairs. Directions should be specified
    #   as Mongo::ASCENDING, Mongo::DESCENDING, or Mongo::GEO2D.
    #
    #   Note that geospatial indexing only works with versions of MongoDB >= 1.3.3+. Keep in mind, too,
    #   that in order to geo-index a given field, that field must reference either an array or a sub-object
    #   where the first two values represent x- and y-coordinates. Examples can be seen below.
    #
    #   Also note that it is permissible to create compound indexes that include a geospatial index as
    #   long as the geospatial index comes first.
    #
    #   If your code calls create_index frequently, you can use Collection#ensure_index to cache these calls
    #   and thereby prevent excessive round trips to the database.
    #
    # @option opts [Boolean] :unique (false) if true, this index will enforce a uniqueness constraint.
    # @option opts [Boolean] :background (false) indicate that the index should be built in the background. This
    #   feature is only available in MongoDB >= 1.3.2.
    # @option opts [Boolean] :drop_dups (nil) If creating a unique index on a collection with pre-existing records,
    #   this option will keep the first document the database indexes and drop all subsequent with duplicate values.
    # @option opts [Integer] :min (nil) specify the minimum longitude and latitude for a geo index.
    # @option opts [Integer] :max (nil) specify the maximum longitude and latitude for a geo index.
    #
    # @example Creating a compound index:
    #   @posts.create_index([['subject', Mongo::ASCENDING], ['created_at', Mongo::DESCENDING]])
    #
    # @example Creating a geospatial index:
    #   @restaurants.create_index([['location', Mongo::GEO2D]])
    #
    #   # Note that this will work only if 'location' represents x,y coordinates:
    #   {'location': [0, 50]}
    #   {'location': {'x' => 0, 'y' => 50}}
    #   {'location': {'latitude' => 0, 'longitude' => 50}}
    #
    # @example A geospatial index with alternate longitude and latitude:
    #   @restaurants.create_index([['location', Mongo::GEO2D]], :min => 500, :max => 500)
    #
    # @return [String] the name of the index created.
    #
    # @core indexes create_index-instance_method
    def create_index(spec, opts={})
      opts[:dropDups] = opts[:drop_dups] if opts[:drop_dups]
      field_spec = parse_index_spec(spec)
      opts = opts.dup
      name = opts.delete(:name) || generate_index_name(field_spec)
      name = name.to_s if name

      generate_indexes(field_spec, name, opts)
      name
    end

    # Calls create_index and sets a flag to not do so again for another X minutes.
    # this time can be specified as an option when initializing a Mongo::DB object as options[:cache_time]
    # Any changes to an index will be propogated through regardless of cache time (e.g., a change of index direction)
    #
    # The parameters and options for this methods are the same as those for Collection#create_index.
    #
    # @example Call sequence:
    #   Time t: @posts.ensure_index([['subject', Mongo::ASCENDING])  -- calls create_index and
    #     sets the 5 minute cache
    #   Time t+2min : @posts.ensure_index([['subject', Mongo::ASCENDING])  -- doesn't do anything
    #   Time t+3min : @posts.ensure_index([['something_else', Mongo::ASCENDING])  -- calls create_index
    #     and sets 5 minute cache
    #   Time t+10min : @posts.ensure_index([['subject', Mongo::ASCENDING])  -- calls create_index and
    #     resets the 5 minute counter
    #
    # @return [String] the name of the index.
    def ensure_index(spec, opts={})
      now = Time.now.utc.to_i
      field_spec = parse_index_spec(spec)

      name = opts[:name] || generate_index_name(field_spec)
      name = name.to_s if name

      if !@cache[name] || @cache[name] <= now
        generate_indexes(field_spec, name, opts)
      end

      # Reset the cache here in case there are any errors inserting. Best to be safe.
      @cache[name] = now + @cache_time
      name
    end

    # Drop a specified index.
    #
    # @param [String] name
    #
    # @core indexes
    def drop_index(name)
      @cache[name.to_s] = nil
      @db.drop_index(@name, name)
    end

    # Drop all indexes.
    #
    # @core indexes
    def drop_indexes
      @cache = {}

      # Note: calling drop_indexes with no args will drop them all.
      @db.drop_index(@name, '*')
    end

    # Drop the entire collection. USE WITH CAUTION.
    def drop
      @db.drop_collection(@name)
    end

    # Atomically update and return a document using MongoDB's findAndModify command. (MongoDB > 1.3.0)
    #
    # @option opts [Hash] :query ({}) a query selector document for matching the desired document.
    # @option opts [Hash] :update (nil) the update operation to perform on the matched document.
    # @option opts [Array, String, OrderedHash] :sort ({}) specify a sort option for the query using any
    #   of the sort options available for Cursor#sort. Sort order is important if the query will be matching
    #   multiple documents since only the first matching document will be updated and returned.
    # @option opts [Boolean] :remove (false) If true, removes the the returned document from the collection.
    # @option opts [Boolean] :new (false) If true, returns the updated document; otherwise, returns the document
    #   prior to update.
    #
    # @return [Hash] the matched document.
    #
    # @core findandmodify find_and_modify-instance_method
    def find_and_modify(opts={})
      cmd = BSON::OrderedHash.new
      cmd[:findandmodify] = @name
      cmd.merge!(opts)
      cmd[:sort] = Mongo::Support.format_order_clause(opts[:sort]) if opts[:sort]

      @db.command(cmd)['value']
    end

    # Perform a map-reduce operation on the current collection.
    #
    # @param [String, BSON::Code] map a map function, written in JavaScript.
    # @param [String, BSON::Code] reduce a reduce function, written in JavaScript.
    #
    # @option opts [Hash] :query ({}) a query selector document, like what's passed to #find, to limit
    #   the operation to a subset of the collection.
    # @option opts [Array] :sort ([]) an array of [key, direction] pairs to sort by. Direction should
    #   be specified as Mongo::ASCENDING (or :ascending / :asc) or Mongo::DESCENDING (or :descending / :desc)
    # @option opts [Integer] :limit (nil) if passing a query, number of objects to return from the collection.
    # @option opts [String, BSON::Code] :finalize (nil) a javascript function to apply to the result set after the
    #   map/reduce operation has finished.
    # @option opts [String] :out (nil) a valid output type. In versions of MongoDB prior to v1.7.6,
    #   this option takes the name of a collection for the output results. In versions 1.7.6 and later,
    #   this option specifies the output type. See the core docs for available output types.
    # @option opts [Boolean] :keeptemp (false) if true, the generated collection will be persisted. The defualt
    #   is false. Note that this option has no effect is versions of MongoDB > v1.7.6.
    # @option opts [Boolean ] :verbose (false) if true, provides statistics on job execution time.
    # @option opts [Boolean] :raw (false) if true, return the raw result object from the map_reduce command, and not
    #   the instantiated collection that's returned by default. Note if a collection name isn't returned in the
    #   map-reduce output (as, for example, when using :out => {:inline => 1}), then you must specify this option
    #   or an ArgumentError will be raised.
    #
    # @return [Collection, Hash] a Mongo::Collection object or a Hash with the map-reduce command's results.
    #
    # @raise ArgumentError if you specify {:out => {:inline => true}} but don't specify :raw => true.
    #
    # @see http://www.mongodb.org/display/DOCS/MapReduce Offical MongoDB map/reduce documentation.
    #
    # @core mapreduce map_reduce-instance_method
    def map_reduce(map, reduce, opts={})
      map    = BSON::Code.new(map) unless map.is_a?(BSON::Code)
      reduce = BSON::Code.new(reduce) unless reduce.is_a?(BSON::Code)
      raw    = opts[:raw]

      hash = BSON::OrderedHash.new
      hash['mapreduce'] = self.name
      hash['map'] = map
      hash['reduce'] = reduce
      hash.merge! opts

      result = @db.command(hash)
      unless Mongo::Support.ok?(result)
        raise Mongo::OperationFailure, "map-reduce failed: #{result['errmsg']}"
      end

      if raw
        result
      elsif result["result"]
        @db[result["result"]]
      else
        raise ArgumentError, "Could not instantiate collection from result. If you specified " +
          "{:out => {:inline => true}}, then you must also specify :raw => true to get the results."
      end
    end
    alias :mapreduce :map_reduce

    # Perform a group aggregation.
    #
    # @param [Hash] opts the options for this group operation. The minimum required are :initial
    #   and :reduce.
    #
    # @option opts [Array, String, Symbol] :key (nil) Either the name of a field or a list of fields to group by (optional).
    # @option opts [String, BSON::Code] :keyf (nil) A JavaScript function to be used to generate the grouping keys (optional).
    # @option opts [String, BSON::Code] :cond ({}) A document specifying a query for filtering the documents over
    #   which the aggregation is run (optional).
    # @option opts [Hash] :initial the initial value of the aggregation counter object (required).
    # @option opts [String, BSON::Code] :reduce (nil) a JavaScript aggregation function (required).
    # @option opts [String, BSON::Code] :finalize (nil) a JavaScript function that receives and modifies
    #   each of the resultant grouped objects. Available only when group is run with command
    #   set to true.
    #
    # @return [Array] the command response consisting of grouped items.
    def group(opts, condition={}, initial={}, reduce=nil, finalize=nil)
      if opts.is_a?(Hash)
        return new_group(opts)
      else
        warn "Collection#group no longer take a list of parameters. This usage is deprecated." +
             "Check out the new API at http://api.mongodb.org/ruby/current/Mongo/Collection.html#group-instance_method"
      end

      reduce = BSON::Code.new(reduce) unless reduce.is_a?(BSON::Code)

      group_command = {
        "group" => {
          "ns"      => @name,
          "$reduce" => reduce,
          "cond"    => condition,
          "initial" => initial
        }
      }

      if opts.is_a?(Symbol)
        raise MongoArgumentError, "Group takes either an array of fields to group by or a JavaScript function" +
          "in the form of a String or BSON::Code."
      end

      unless opts.nil?
        if opts.is_a? Array
          key_type = "key"
          key_value = {}
          opts.each { |k| key_value[k] = 1 }
        else
          key_type  = "$keyf"
          key_value = opts.is_a?(BSON::Code) ? opts : BSON::Code.new(opts)
        end

        group_command["group"][key_type] = key_value
      end

      finalize = BSON::Code.new(finalize) if finalize.is_a?(String)
      if finalize.is_a?(BSON::Code)
        group_command['group']['finalize'] = finalize
      end

      result = @db.command(group_command)

      if Mongo::Support.ok?(result)
        result["retval"]
      else
        raise OperationFailure, "group command failed: #{result['errmsg']}"
      end
    end

    private

    def new_group(opts={})
      reduce   =  opts[:reduce]
      finalize =  opts[:finalize]
      cond     =  opts.fetch(:cond, {})
      initial  =  opts[:initial]

      if !(reduce && initial)
        raise MongoArgumentError, "Group requires at minimum values for initial and reduce."
      end

      cmd = {
        "group" => {
          "ns"      => @name,
          "$reduce" => reduce.to_bson_code,
          "cond"    => cond,
          "initial" => initial
        }
      }

      if finalize
        cmd['group']['finalize'] = finalize.to_bson_code
      end

      if key = opts[:key]
        if key.is_a?(String) || key.is_a?(Symbol)
          key = [key]
        end
        key_value = {}
        key.each { |k| key_value[k] = 1 }
        cmd["group"]["key"] = key_value
      elsif keyf = opts[:keyf]
        cmd["group"]["$keyf"] = keyf.to_bson_code
      end

      result = @db.command(cmd)
      result["retval"]
    end

    public

    # Return a list of distinct values for +key+ across all
    # documents in the collection. The key may use dot notation
    # to reach into an embedded object.
    #
    # @param [String, Symbol, OrderedHash] key or hash to group by.
    # @param [Hash] query a selector for limiting the result set over which to group.
    #
    # @example Saving zip codes and ages and returning distinct results.
    #   @collection.save({:zip => 10010, :name => {:age => 27}})
    #   @collection.save({:zip => 94108, :name => {:age => 24}})
    #   @collection.save({:zip => 10010, :name => {:age => 27}})
    #   @collection.save({:zip => 99701, :name => {:age => 24}})
    #   @collection.save({:zip => 94108, :name => {:age => 27}})
    #
    #   @collection.distinct(:zip)
    #     [10010, 94108, 99701]
    #   @collection.distinct("name.age")
    #     [27, 24]
    #
    #   # You may also pass a document selector as the second parameter
    #   # to limit the documents over which distinct is run:
    #   @collection.distinct("name.age", {"name.age" => {"$gt" => 24}})
    #     [27]
    #
    # @return [Array] an array of distinct values.
    def distinct(key, query=nil)
      raise MongoArgumentError unless [String, Symbol].include?(key.class)
      command = BSON::OrderedHash.new
      command[:distinct] = @name
      command[:key]      = key.to_s
      command[:query]    = query

      @db.command(command)["values"]
    end

    # Rename this collection.
    #
    # Note: If operating in auth mode, the client must be authorized as an admin to
    # perform this operation.
    #
    # @param [String] new_name the new name for this collection
    #
    # @return [String] the name of the new collection.
    #
    # @raise [Mongo::InvalidNSName] if +new_name+ is an invalid collection name.
    def rename(new_name)
      case new_name
      when Symbol, String
      else
        raise TypeError, "new_name must be a string or symbol"
      end

      new_name = new_name.to_s

      if new_name.empty? or new_name.include? ".."
        raise Mongo::InvalidNSName, "collection names cannot be empty"
      end
      if new_name.include? "$"
        raise Mongo::InvalidNSName, "collection names must not contain '$'"
      end
      if new_name.match(/^\./) or new_name.match(/\.$/)
        raise Mongo::InvalidNSName, "collection names must not start or end with '.'"
      end

      @db.rename_collection(@name, new_name)
      @name = new_name
    end

    # Get information on the indexes for this collection.
    #
    # @return [Hash] a hash where the keys are index names.
    #
    # @core indexes
    def index_information
      @db.index_information(@name)
    end

    # Return a hash containing options that apply to this collection.
    # For all possible keys and values, see DB#create_collection.
    #
    # @return [Hash] options that apply to this collection.
    def options
      @db.collections_info(@name).next_document['options']
    end

    # Return stats on the collection. Uses MongoDB's collstats command.
    #
    # @return [Hash]
    def stats
      @db.command({:collstats => @name})
    end

    # Get the number of documents in this collection.
    #
    # @return [Integer]
    def count
      find().count()
    end

    alias :size :count

    protected

    def normalize_hint_fields(hint)
      case hint
      when String
        {hint => 1}
      when Hash
        hint
      when nil
        nil
      else
        h = BSON::OrderedHash.new
        hint.to_a.each { |k| h[k] = 1 }
        h
      end
    end

    private

    def parse_index_spec(spec)
      field_spec = BSON::OrderedHash.new
      if spec.is_a?(String) || spec.is_a?(Symbol)
        field_spec[spec.to_s] = 1
      elsif spec.is_a?(Array) && spec.all? {|field| field.is_a?(Array) }
        spec.each do |f|
          if [Mongo::ASCENDING, Mongo::DESCENDING, Mongo::GEO2D].include?(f[1])
            field_spec[f[0].to_s] = f[1]
          else
            raise MongoArgumentError, "Invalid index field #{f[1].inspect}; " + 
              "should be one of Mongo::ASCENDING (1), Mongo::DESCENDING (-1) or Mongo::GEO2D ('2d')."
          end
        end
      else
        raise MongoArgumentError, "Invalid index specification #{spec.inspect}; " + 
          "should be either a string, symbol, or an array of arrays."
      end
      field_spec
    end

    def generate_indexes(field_spec, name, opts)
      selector = {
        :name   => name,
        :ns     => "#{@db.name}.#{@name}",
        :key    => field_spec
      }
      selector.merge!(opts)

      begin
      insert_documents([selector], Mongo::DB::SYSTEM_INDEX_COLLECTION, false, true)

      rescue Mongo::OperationFailure => e
        if selector[:dropDups] && e.message =~ /^11000/
          # NOP. If the user is intentionally dropping dups, we can ignore duplicate key errors.
        else
          raise Mongo::OperationFailure, "Failed to create index #{selector.inspect} with the following error: " +
           "#{e.message}"
        end
      end

      nil
    end

    # Sends a Mongo::Constants::OP_INSERT message to the database.
    # Takes an array of +documents+, an optional +collection_name+, and a
    # +check_keys+ setting.
    def insert_documents(documents, collection_name=@name, check_keys=true, safe=false)
      # Initial byte is 0.
      message = BSON::ByteBuffer.new("\0\0\0\0")
      BSON::BSON_RUBY.serialize_cstr(message, "#{@db.name}.#{collection_name}")
      documents.each do |doc|
        message.put_binary(BSON::BSON_CODER.serialize(doc, check_keys, true).to_s)
      end
      raise InvalidOperation, "Exceded maximum insert size of 16,000,000 bytes" if message.size > 16_000_000

      @connection.instrument(:insert, :database => @db.name, :collection => collection_name, :documents => documents) do
        if safe
          @connection.send_message_with_safe_check(Mongo::Constants::OP_INSERT, message, @db.name, nil, safe)
        else
          @connection.send_message(Mongo::Constants::OP_INSERT, message)
        end
      end
      documents.collect { |o| o[:_id] || o['_id'] }
    end

    def generate_index_name(spec)
      indexes = []
      spec.each_pair do |field, direction|
        indexes.push("#{field}_#{direction}")
      end
      indexes.join("_")
    end
  end

end
