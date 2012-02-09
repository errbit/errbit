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
# ++

require 'socket'
require 'timeout'
require 'thread'

module Mongo

  # A MongoDB database.
  class DB

    SYSTEM_NAMESPACE_COLLECTION = "system.namespaces"
    SYSTEM_INDEX_COLLECTION = "system.indexes"
    SYSTEM_PROFILE_COLLECTION = "system.profile"
    SYSTEM_USER_COLLECTION = "system.users"
    SYSTEM_JS_COLLECTION = "system.js"
    SYSTEM_COMMAND_COLLECTION = "$cmd"

    # Counter for generating unique request ids.
    @@current_request_id = 0

    # Strict mode enforces collection existence checks. When +true+,
    # asking for a collection that does not exist, or trying to create a
    # collection that already exists, raises an error.
    #
    # Strict mode is disabled by default, but enabled (+true+) at any time.
    attr_writer :strict

    # Returns the value of the +strict+ flag.
    def strict?; @strict; end

    # The name of the database and the local safe option.
    attr_reader :name, :safe

    # The Mongo::Connection instance connecting to the MongoDB server.
    attr_reader :connection

    # The length of time that Collection.ensure_index should cache index calls
    attr_accessor :cache_time

    # Instances of DB are normally obtained by calling Mongo#db.
    #
    # @param [String] name the database name.
    # @param [Mongo::Connection] connection a connection object pointing to MongoDB. Note
    #   that databases are usually instantiated via the Connection class. See the examples below.
    #
    # @option opts [Boolean] :strict (False) If true, collections must exist to be accessed and must
    #   not exist to be created. See DB#collection and DB#create_collection.
    #
    # @option opts [Object, #create_pk(doc)] :pk (Mongo::ObjectId) A primary key factory object,
    #   which should take a hash and return a hash which merges the original hash with any primary key
    #   fields the factory wishes to inject. (NOTE: if the object already has a primary key,
    #   the factory should not inject a new key).
    #
    # @option opts [Boolean, Hash] :safe (false) Set the default safe-mode options
    #   propagated to Collection objects instantiated off of this DB. If no
    #   value is provided, the default value set on this instance's Connection object will be used. This
    #   default can be overridden upon instantiation of any collection by explicity setting a :safe value
    #   on initialization
    # @option opts [Integer] :cache_time (300) Set the time that all ensure_index calls should cache the command.
    #
    # @core databases constructor_details
    def initialize(name, connection, opts={})
      @name       = Mongo::Support.validate_db_name(name)
      @connection = connection
      @strict     = opts[:strict]
      @pk_factory = opts[:pk]
      @safe       = opts.fetch(:safe, @connection.safe)
      @cache_time = opts[:cache_time] || 300 #5 minutes.
    end

    # Authenticate with the given username and password. Note that mongod
    # must be started with the --auth option for authentication to be enabled.
    #
    # @param [String] username
    # @param [String] password
    # @param [Boolean] save_auth
    #   Save this authentication to the connection object using Connection#add_auth. This
    #   will ensure that the authentication will be applied on database reconnect. Note
    #   that this value must be true when using connection pooling.
    #
    # @return [Boolean]
    #
    # @raise [AuthenticationError]
    #
    # @core authenticate authenticate-instance_method
    def authenticate(username, password, save_auth=true)
      if @connection.pool_size > 1
        if !save_auth
          raise MongoArgumentError, "If using connection pooling, :save_auth must be set to true."
        end
        @connection.authenticate_pools
      end

      issue_authentication(username, password, save_auth)
    end

    def issue_authentication(username, password, save_auth=true, opts={})
      doc = command({:getnonce => 1}, :check_response => false, :socket => opts[:socket])
      raise MongoDBError, "Error retrieving nonce: #{doc}" unless ok?(doc)
      nonce = doc['nonce']

      auth = BSON::OrderedHash.new
      auth['authenticate'] = 1
      auth['user'] = username
      auth['nonce'] = nonce
      auth['key'] = Mongo::Support.auth_key(username, password, nonce)
      if ok?(self.command(auth, :check_response => false, :socket => opts[:socket]))
        if save_auth
          @connection.add_auth(@name, username, password)
        end
        true
      else
        raise(Mongo::AuthenticationError, "Failed to authenticate user '#{username}' on db '#{self.name}'")
      end
    end

    # Adds a stored Javascript function to the database which can executed  
    # server-side in map_reduce, db.eval and $where clauses.
    #
    # @param [String] function_name
    # @param [String] code
    #
    # @return [String] the function name saved to the database
    def add_stored_function(function_name, code)
      self[SYSTEM_JS_COLLECTION].save(
        {
          "_id" => function_name, 
          :value => BSON::Code.new(code)
        }
      )
    end

    # Removes stored Javascript function from the database.  Returns
    # false if the function does not exist
    #
    # @param [String] function_name
    #
    # @return [Boolean]
    def remove_stored_function(function_name)
      if self[SYSTEM_JS_COLLECTION].find_one({"_id" => function_name})
        self[SYSTEM_JS_COLLECTION].remove({"_id" => function_name}, :safe => true)
      else
        return false
      end
    end

    # Adds a user to this database for use with authentication. If the user already
    # exists in the system, the password will be updated.
    #
    # @param [String] username
    # @param [String] password
    #
    # @return [Hash] an object representing the user.
    def add_user(username, password)
      users = self[SYSTEM_USER_COLLECTION]
      user  = users.find_one({:user => username}) || {:user => username}
      user['pwd'] = Mongo::Support.hash_password(username, password)
      users.save(user)
      return user
    end

    # Remove the given user from this database. Returns false if the user
    # doesn't exist in the system.
    #
    # @param [String] username
    #
    # @return [Boolean]
    def remove_user(username)
      if self[SYSTEM_USER_COLLECTION].find_one({:user => username})
        self[SYSTEM_USER_COLLECTION].remove({:user => username}, :safe => true)
      else
        return false
      end
    end

    # Deauthorizes use for this database for this connection. Also removes
    # any saved authentication in the connection class associated with this
    # database.
    #
    # @raise [MongoDBError] if logging out fails.
    #
    # @return [Boolean]
    def logout(opts={})
      if @connection.pool_size > 1
        @connection.logout_pools(@name)
      end

      issue_logout(opts)
    end

    def issue_logout(opts={})
      doc = command({:logout => 1}, :socket => opts[:socket])
      if ok?(doc)
        @connection.remove_auth(@name)
        true
      else
        raise MongoDBError, "error logging out: #{doc.inspect}"
      end
    end

    # Get an array of collection names in this database.
    #
    # @return [Array]
    def collection_names
      names = collections_info.collect { |doc| doc['name'] || '' }
      names = names.delete_if {|name| name.index(@name).nil? || name.index('$')}
      names.map {|name| name.sub(@name + '.', '')}
    end

    # Get an array of Collection instances, one for each collection in this database.
    #
    # @return [Array<Mongo::Collection>]
    def collections
      collection_names.map do |name|
        Collection.new(name, self)
      end
    end

    # Get info on system namespaces (collections). This method returns
    # a cursor which can be iterated over. For each collection, a hash
    # will be yielded containing a 'name' string and, optionally, an 'options' hash.
    #
    # @param [String] coll_name return info for the specifed collection only.
    #
    # @return [Mongo::Cursor]
    def collections_info(coll_name=nil)
      selector = {}
      selector[:name] = full_collection_name(coll_name) if coll_name
      Cursor.new(Collection.new(SYSTEM_NAMESPACE_COLLECTION, self), :selector => selector)
    end

    # Create a collection.
    #
    # new collection. If +strict+ is true, will raise an error if
    # collection +name+ already exists.
    #
    # @param [String, Symbol] name the name of the new collection.
    #
    # @option opts [Boolean] :capped (False) created a capped collection.
    #
    # @option opts [Integer] :size (Nil) If +capped+ is +true+,
    #   specifies the maximum number of bytes for the capped collection.
    #   If +false+, specifies the number of bytes allocated
    #   for the initial extent of the collection.
    #
    # @option opts [Integer] :max (Nil) If +capped+ is +true+, indicates
    #   the maximum number of records in a capped collection.
    #
    # @raise [MongoDBError] raised under two conditions:
    #   either we're in +strict+ mode and the collection
    #   already exists or collection creation fails on the server.
    #
    # @return [Mongo::Collection]
    def create_collection(name, opts={})
      if collection_names.include?(name.to_s)
        if strict?
          raise MongoDBError, "Collection #{name} already exists. " +
            "Currently in strict mode."
        else
          return Collection.new(name, self, opts)
        end
      end

      # Create a new collection.
      oh = BSON::OrderedHash.new
      oh[:create] = name
      doc = command(oh.merge(opts || {}))
      return Collection.new(name, self, :pk => @pk_factory) if ok?(doc)
      raise MongoDBError, "Error creating collection: #{doc.inspect}"
    end

    # Get a collection by name.
    #
    # @param [String, Symbol] name the collection name.
    # @param [Hash] opts any valid options that can be passed to Collection#new.
    #
    # @raise [MongoDBError] if collection does not already exist and we're in
    #   +strict+ mode.
    #
    # @return [Mongo::Collection]
    def collection(name, opts={})
      if strict? && !collection_names.include?(name.to_s)
        raise Mongo::MongoDBError, "Collection #{name} doesn't exist. " +
          "Currently in strict mode."
      else
        opts = opts.dup
        opts[:safe] = opts.fetch(:safe, @safe)
        opts.merge!(:pk => @pk_factory) unless opts[:pk]
        Collection.new(name, self, opts)
      end
    end
    alias_method :[], :collection

    # Drop a collection by +name+.
    #
    # @param [String, Symbol] name
    #
    # @return [Boolean] +true+ on success or +false+ if the collection name doesn't exist.
    def drop_collection(name)
      return true unless collection_names.include?(name.to_s)

      ok?(command(:drop => name))
    end

    # Run the getlasterror command with the specified replication options.
    #
    # @option opts [Boolean] :fsync (false)
    # @option opts [Integer] :w (nil)
    # @option opts [Integer] :wtimeout (nil)
    #
    # @return [Hash] the entire response to getlasterror.
    #
    # @raise [MongoDBError] if the operation fails.
    def get_last_error(opts={})
      cmd = BSON::OrderedHash.new
      cmd[:getlasterror] = 1
      cmd.merge!(opts)
      doc = command(cmd, :check_response => false)
      raise MongoDBError, "error retrieving last error: #{doc.inspect}" unless ok?(doc)
      doc
    end

    # Return +true+ if an error was caused by the most recently executed
    # database operation.
    #
    # @return [Boolean]
    def error?
      get_last_error['err'] != nil
    end

    # Get the most recent error to have occured on this database.
    #
    # This command only returns errors that have occured since the last call to
    # DB#reset_error_history - returns +nil+ if there is no such error.
    #
    # @return [String, Nil] the text of the error or +nil+ if no error has occurred.
    def previous_error
      error = command(:getpreverror => 1)
      if error["err"]
        error
      else
        nil
      end
    end

    # Reset the error history of this database
    #
    # Calls to DB#previous_error will only return errors that have occurred
    # since the most recent call to this method.
    #
    # @return [Hash]
    def reset_error_history
      command(:reseterror => 1)
    end

    # Dereference a DBRef, returning the document it points to.
    #
    # @param [Mongo::DBRef] dbref
    #
    # @return [Hash] the document indicated by the db reference.
    #
    # @see http://www.mongodb.org/display/DOCS/DB+Ref MongoDB DBRef spec.
    def dereference(dbref)
      collection(dbref.namespace).find_one("_id" => dbref.object_id)
    end

    # Evaluate a JavaScript expression in MongoDB.
    #
    # @param [String, Code] code a JavaScript expression to evaluate server-side.
    # @param [Integer, Hash] args any additional argument to be passed to the +code+ expression when 
    #   it's run on the server.
    #
    # @return [String] the return value of the function.
    def eval(code, *args)
      if not code.is_a? BSON::Code
        code = BSON::Code.new(code)
      end

      oh = BSON::OrderedHash.new
      oh[:$eval] = code
      oh[:args]  = args
      doc = command(oh)
      doc['retval']
    end

    # Rename a collection.
    #
    # @param [String] from original collection name.
    # @param [String] to new collection name.
    #
    # @return [True] returns +true+ on success.
    #
    # @raise MongoDBError if there's an error renaming the collection.
    def rename_collection(from, to)
      oh = BSON::OrderedHash.new
      oh[:renameCollection] = "#{@name}.#{from}"
      oh[:to] = "#{@name}.#{to}"
      doc = DB.new('admin', @connection).command(oh, :check_response => false)
      ok?(doc) || raise(MongoDBError, "Error renaming collection: #{doc.inspect}")
    end

    # Drop an index from a given collection. Normally called from
    # Collection#drop_index or Collection#drop_indexes.
    #
    # @param [String] collection_name
    # @param [String] index_name
    #
    # @return [True] returns +true+ on success.
    #
    # @raise MongoDBError if there's an error renaming the collection.
    def drop_index(collection_name, index_name)
      oh = BSON::OrderedHash.new
      oh[:deleteIndexes] = collection_name
      oh[:index] = index_name.to_s
      doc = command(oh, :check_response => false)
      ok?(doc) || raise(MongoDBError, "Error with drop_index command: #{doc.inspect}")
    end

    # Get information on the indexes for the given collection.
    # Normally called by Collection#index_information.
    #
    # @param [String] collection_name
    #
    # @return [Hash] keys are index names and the values are lists of [key, direction] pairs
    #   defining the index.
    def index_information(collection_name)
      sel  = {:ns => full_collection_name(collection_name)}
      info = {}
      Cursor.new(Collection.new(SYSTEM_INDEX_COLLECTION, self), :selector => sel).each do |index|
        info[index['name']] = index
      end
      info
    end

    # Return stats on this database. Uses MongoDB's dbstats command.
    #
    # @return [Hash]
    def stats
      self.command({:dbstats => 1})
    end

    # Return +true+ if the supplied +doc+ contains an 'ok' field with the value 1.
    #
    # @param [Hash] doc
    #
    # @return [Boolean]
    def ok?(doc)
      Mongo::Support.ok?(doc)
    end

    # Send a command to the database.
    #
    # Note: DB commands must start with the "command" key. For this reason,
    # any selector containing more than one key must be an OrderedHash.
    #
    # Note also that a command in MongoDB is just a kind of query
    # that occurs on the system command collection ($cmd). Examine this method's implementation
    # to see how it works.
    #
    # @param [OrderedHash, Hash] selector an OrderedHash, or a standard Hash with just one
    # key, specifying the command to be performed. In Ruby 1.9, OrderedHash isn't necessary since
    # hashes are ordered by default.
    #
    # @option opts [Boolean] :check_response (true) If +true+, raises an exception if the
    # command fails.
    # @option opts [Socket] :socket a socket to use for sending the command. This is mainly for internal use.
    #
    # @return [Hash]
    #
    # @core commands command_instance-method
    def command(selector, opts={})
      check_response = opts.fetch(:check_response, true)
      socket         = opts[:socket]
      raise MongoArgumentError, "command must be given a selector" unless selector.is_a?(Hash) && !selector.empty?
      if selector.keys.length > 1 && RUBY_VERSION < '1.9' && selector.class != BSON::OrderedHash
        raise MongoArgumentError, "DB#command requires an OrderedHash when hash contains multiple keys"
      end

      begin
        result = Cursor.new(system_command_collection,
          :limit => -1, :selector => selector, :socket => socket).next_document
      rescue OperationFailure => ex
        raise OperationFailure, "Database command '#{selector.keys.first}' failed: #{ex.message}"
      end

      if result.nil?
        raise OperationFailure, "Database command '#{selector.keys.first}' failed: returned null."
      elsif (check_response && !ok?(result))
        raise OperationFailure, "Database command '#{selector.keys.first}' failed: #{result.inspect}"
      else
        result
      end
    end

    # A shortcut returning db plus dot plus collection name.
    #
    # @param [String] collection_name
    #
    # @return [String]
    def full_collection_name(collection_name)
      "#{@name}.#{collection_name}"
    end

    # The primary key factory object (or +nil+).
    #
    # @return [Object, Nil]
    def pk_factory
      @pk_factory
    end

    # Specify a primary key factory if not already set.
    #
    # @raise [MongoArgumentError] if the primary key factory has already been set.
    def pk_factory=(pk_factory)
      if @pk_factory
        raise MongoArgumentError, "Cannot change primary key factory once it's been set"
      end

      @pk_factory = pk_factory
    end

    # Return the current database profiling level. If profiling is enabled, you can
    # get the results using DB#profiling_info.
    #
    # @return [Symbol] :off, :slow_only, or :all
    #
    # @core profiling profiling_level-instance_method
    def profiling_level
      oh = BSON::OrderedHash.new
      oh[:profile] = -1
      doc = command(oh, :check_response => false)
      raise "Error with profile command: #{doc.inspect}" unless ok?(doc) && doc['was'].kind_of?(Numeric)
      case doc['was'].to_i
      when 0
        :off
      when 1
        :slow_only
      when 2
        :all
      else
        raise "Error: illegal profiling level value #{doc['was']}"
      end
    end

    # Set this database's profiling level. If profiling is enabled, you can
    # get the results using DB#profiling_info.
    #
    # @param [Symbol] level acceptable options are +:off+, +:slow_only+, or +:all+.
    def profiling_level=(level)
      oh = BSON::OrderedHash.new
      oh[:profile] = case level
                     when :off
                       0
                     when :slow_only
                       1
                     when :all
                       2
                     else
                       raise "Error: illegal profiling level value #{level}"
                     end
      doc = command(oh, :check_response => false)
      ok?(doc) || raise(MongoDBError, "Error with profile command: #{doc.inspect}")
    end

    # Get the current profiling information.
    #
    # @return [Array] a list of documents containing profiling information.
    def profiling_info
      Cursor.new(Collection.new(SYSTEM_PROFILE_COLLECTION, self), :selector => {}).to_a
    end

    # Validate a named collection.
    #
    # @param [String] name the collection name.
    #
    # @return [Hash] validation information.
    #
    # @raise [MongoDBError] if the command fails or there's a problem with the validation
    #   data, or if the collection is invalid.
    def validate_collection(name)
      cmd = BSON::OrderedHash.new
      cmd[:validate] = name
      cmd[:full] = true
      doc = command(cmd, :check_response => false)
      if !ok?(doc)
        raise MongoDBError, "Error with validate command: #{doc.inspect}"
      end
      if (doc.has_key?('valid') && !doc['valid']) || (doc['result'] =~ /\b(exception|corrupt)\b/i)
        raise MongoDBError, "Error: invalid collection #{name}: #{doc.inspect}"
      end
      doc
    end

    private

    def system_command_collection
      Collection.new(SYSTEM_COMMAND_COLLECTION, self)
    end
  end
end
