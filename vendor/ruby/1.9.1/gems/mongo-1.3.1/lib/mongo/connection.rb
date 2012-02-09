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

require 'set'
require 'socket'
require 'thread'

module Mongo

  # Instantiates and manages connections to MongoDB.
  class Connection
    TCPSocket = ::TCPSocket
    Mutex = ::Mutex
    ConditionVariable = ::ConditionVariable

    # Abort connections if a ConnectionError is raised.
    Thread.abort_on_exception = true

    DEFAULT_PORT = 27017
    STANDARD_HEADER_SIZE = 16
    RESPONSE_HEADER_SIZE = 20

    attr_reader :logger, :size, :auths, :primary, :safe, :primary_pool, :host_to_try, :pool_size

    # Counter for generating unique request ids.
    @@current_request_id = 0

    # Create a connection to single MongoDB instance.
    #
    # You may specify whether connection to slave is permitted.
    # In all cases, the default host is "localhost" and the default port is 27017.
    #
    # If you're connecting to a replica set, you'll need to use ReplSetConnection.new instead.
    #
    # Once connected to a replica set, you can find out which nodes are primary, secondary, and
    # arbiters with the corresponding accessors: Connection#primary, Connection#secondaries, and
    # Connection#arbiters. This is useful if your application needs to connect manually to nodes other
    # than the primary.
    #
    # @param [String, Hash] host.
    # @param [Integer] port specify a port number here if only one host is being specified.
    #
    # @option opts [Boolean, Hash] :safe (false) Set the default safe-mode options
    #   propogated to DB objects instantiated off of this Connection. This
    #   default can be overridden upon instantiation of any DB by explicity setting a :safe value
    #   on initialization.
    # @option opts [Boolean] :slave_ok (false) Must be set to +true+ when connecting
    #   to a single, slave node.
    # @option opts [Logger, #debug] :logger (nil) A Logger instance for debugging driver ops. Note that
    #   logging negatively impacts performance; therefore, it should not be used for high-performance apps.
    # @option opts [Integer] :pool_size (1) The maximum number of socket connections allowed per
    #   connection pool. Note: this setting is relevant only for multi-threaded applications.
    # @option opts [Float] :timeout (5.0) When all of the connections a pool are checked out,
    #   this is the number of seconds to wait for a new connection to be released before throwing an exception.
    #   Note: this setting is relevant only for multi-threaded applications (which in Ruby are rare).
    # @option opts [Float] :op_timeout (nil) The number of seconds to wait for a read operation to time out.
    #   Disabled by default.
    #
    # @example localhost, 27017
    #   Connection.new
    #
    # @example localhost, 27017
    #   Connection.new("localhost")
    #
    # @example localhost, 3000, max 5 connections, with max 5 seconds of wait time.
    #   Connection.new("localhost", 3000, :pool_size => 5, :timeout => 5)
    #
    # @example localhost, 3000, where this node may be a slave
    #   Connection.new("localhost", 3000, :slave_ok => true)
    #
    # @see http://api.mongodb.org/ruby/current/file.REPLICA_SETS.html Replica sets in Ruby
    #
    # @raise [ReplicaSetConnectionError] This is raised if a replica set name is specified and the
    #   driver fails to connect to a replica set with that name.
    #
    # @core connections
    def initialize(host=nil, port=nil, opts={})
      @host_to_try = format_pair(host, port)

      # Host and port of current master.
      @host = @port = nil

      # slave_ok can be true only if one node is specified
      @slave_ok = opts[:slave_ok]

      setup(opts)
    end

    # DEPRECATED
    #
    # Initialize a connection to a MongoDB replica set using an array of seed nodes.
    #
    # The seed nodes specified will be used on the initial connection to the replica set, but note
    # that this list of nodes will be replced by the list of canonical nodes returned by running the
    # is_master command on the replica set.
    #
    # @param nodes [Array] An array of arrays, each of which specifies a host and port.
    # @param opts [Hash] Any of the available options that can be passed to Connection.new.
    #
    # @option opts [String] :rs_name (nil) The name of the replica set to connect to. An exception will be
    #   raised if unable to connect to a replica set with this name.
    # @option opts [Boolean] :read_secondary (false) When true, this connection object will pick a random slave
    #   to send reads to.
    #
    # @example
    #   Connection.multi([["db1.example.com", 27017], ["db2.example.com", 27017]])
    #
    # @example This connection will read from a random secondary node.
    #   Connection.multi([["db1.example.com", 27017], ["db2.example.com", 27017], ["db3.example.com", 27017]],
    #                   :read_secondary => true)
    #
    # @return [Mongo::Connection]
    #
    # @deprecated
    def self.multi(nodes, opts={})
      warn "Connection.multi is now deprecated. Please use ReplSetConnection.new instead."

      nodes << opts
      ReplSetConnection.new(*nodes)
    end

    # Initialize a connection to MongoDB using the MongoDB URI spec:
    #
    # @param uri [String]
    #   A string of the format mongodb://[username:password@]host1[:port1][,host2[:port2],...[,hostN[:portN]]][/database]
    #
    # @param opts Any of the options available for Connection.new
    #
    # @return [Mongo::Connection, Mongo::ReplSetConnection]
    def self.from_uri(string, extra_opts={})
      uri = URIParser.new(string)
      opts = uri.connection_options
      opts.merge!(extra_opts)

      if uri.nodes.length == 1
        opts.merge!({:auths => uri.auths})
        Connection.new(uri.nodes[0][0], uri.nodes[0][1], opts)
      elsif uri.nodes.length > 1
        nodes = uri.nodes.clone
        nodes_with_opts = nodes << opts
        ReplSetConnection.new(*nodes_with_opts)
      else
        raise MongoArgumentError, "No nodes specified. Please ensure that you've provided at least one node."
      end
    end

    # The host name used for this connection.
    #
    # @return [String]
    def host
      @primary_pool.host
    end

    # The port used for this connection.
    #
    # @return [Integer]
    def port
      @primary_pool.port
    end

    # Fsync, then lock the mongod process against writes. Use this to get
    # the datafiles in a state safe for snapshotting, backing up, etc.
    #
    # @return [BSON::OrderedHash] the command response
    def lock!
      cmd = BSON::OrderedHash.new
      cmd[:fsync] = 1
      cmd[:lock]  = true
      self['admin'].command(cmd)
    end

    # Is this database locked against writes?
    #
    # @return [Boolean]
    def locked?
      self['admin']['$cmd.sys.inprog'].find_one['fsyncLock'] == 1
    end

    # Unlock a previously fsync-locked mongod process.
    #
    # @return [BSON::OrderedHash] command response
    def unlock!
      self['admin']['$cmd.sys.unlock'].find_one
    end

    # Apply each of the saved database authentications.
    #
    # @return [Boolean] returns true if authentications exist and succeeed, false
    #   if none exists.
    #
    # @raise [AuthenticationError] raises an exception if any one
    #   authentication fails.
    def apply_saved_authentication(opts={})
      return false if @auths.empty?
      @auths.each do |auth|
        self[auth['db_name']].issue_authentication(auth['username'], auth['password'], false,
          :socket => opts[:socket])
      end
      true
    end

    # Save an authentication to this connection. When connecting,
    # the connection will attempt to re-authenticate on every db
    # specificed in the list of auths. This method is called automatically
    # by DB#authenticate.
    #
    # Note: this method will not actually issue an authentication command. To do that,
    # either run Connection#apply_saved_authentication or DB#authenticate.
    #
    # @param [String] db_name
    # @param [String] username
    # @param [String] password
    #
    # @return [Hash] a hash representing the authentication just added.
    def add_auth(db_name, username, password)
      remove_auth(db_name)
      auth = {}
      auth['db_name']  = db_name
      auth['username'] = username
      auth['password'] = password
      @auths << auth
      auth
    end

    # Remove a saved authentication for this connection.
    #
    # @param [String] db_name
    #
    # @return [Boolean]
    def remove_auth(db_name)
      return unless @auths
      if @auths.reject! { |a| a['db_name'] == db_name }
        true
      else
        false
      end
    end

    # Remove all authenication information stored in this connection.
    #
    # @return [true] this operation return true because it always succeeds.
    def clear_auths
      @auths = []
      true
    end

    def authenticate_pools
      @primary_pool.authenticate_existing
    end

    def logout_pools(db)
      @primary_pool.logout_existing(db)
    end

    # Return a hash with all database names
    # and their respective sizes on disk.
    #
    # @return [Hash]
    def database_info
      doc = self['admin'].command({:listDatabases => 1})
      doc['databases'].each_with_object({}) do |db, info|
        info[db['name']] = db['sizeOnDisk'].to_i
      end
    end

    # Return an array of database names.
    #
    # @return [Array]
    def database_names
      database_info.keys
    end

    # Return a database with the given name.
    # See DB#new for valid options hash parameters.
    #
    # @param [String] db_name a valid database name.
    # @param [Hash] opts options to be passed to the DB constructor.
    #
    # @return [Mongo::DB]
    #
    # @core databases db-instance_method
    def db(db_name, opts={})
      DB.new(db_name, self, opts)
    end

    # Shortcut for returning a database. Use DB#db to accept options.
    #
    # @param [String] db_name a valid database name.
    #
    # @return [Mongo::DB]
    #
    # @core databases []-instance_method
    def [](db_name)
      DB.new(db_name, self, :safe => @safe)
    end

    # Drop a database.
    #
    # @param [String] name name of an existing database.
    def drop_database(name)
      self[name].command(:dropDatabase => 1)
    end

    # Copy the database +from+ to +to+ on localhost. The +from+ database is
    # assumed to be on localhost, but an alternate host can be specified.
    #
    # @param [String] from name of the database to copy from.
    # @param [String] to name of the database to copy to.
    # @param [String] from_host host of the 'from' database.
    # @param [String] username username for authentication against from_db (>=1.3.x).
    # @param [String] password password for authentication against from_db (>=1.3.x).
    def copy_database(from, to, from_host="localhost", username=nil, password=nil)
      oh = BSON::OrderedHash.new
      oh[:copydb]   = 1
      oh[:fromhost] = from_host
      oh[:fromdb]   = from
      oh[:todb]     = to
      if username || password
        unless username && password
          raise MongoArgumentError, "Both username and password must be supplied for authentication."
        end
        nonce_cmd = BSON::OrderedHash.new
        nonce_cmd[:copydbgetnonce] = 1
        nonce_cmd[:fromhost] = from_host
        result = self["admin"].command(nonce_cmd)
        oh[:nonce] = result["nonce"]
        oh[:username] = username
        oh[:key] = Mongo::Support.auth_key(username, password, oh[:nonce])
      end
      self["admin"].command(oh)
    end

    # Checks if a server is alive. This command will return immediately 
    # even if the server is in a lock.
    #
    # @return [Hash]
    def ping
      self["admin"].command({:ping => 1})
    end

    # Get the build information for the current connection.
    #
    # @return [Hash]
    def server_info
      self["admin"].command({:buildinfo => 1})
    end


    # Get the build version of the current server.
    #
    # @return [Mongo::ServerVersion]
    #   object allowing easy comparability of version.
    def server_version
      ServerVersion.new(server_info["version"])
    end

    # Is it okay to connect to a slave?
    #
    # @return [Boolean]
    def slave_ok?
      @slave_ok
    end

    # Send a message to MongoDB, adding the necessary headers.
    #
    # @param [Integer] operation a MongoDB opcode.
    # @param [BSON::ByteBuffer] message a message to send to the database.
    #
    # @option opts [Symbol] :connection (:writer) The connection to which
    #   this message should be sent. Valid options are :writer and :reader.
    #
    # @return [Integer] number of bytes sent
    def send_message(operation, message, opts={})
      if opts.is_a?(String)
        warn "Connection#send_message no longer takes a string log message. " +
          "Logging is now handled within the Collection and Cursor classes."
        opts = {}
      end

      connection = opts.fetch(:connection, :writer)

      begin
        add_message_headers(message, operation)
        packed_message = message.to_s

        if connection == :writer
          socket = checkout_writer
        else
          socket = checkout_reader
        end

        send_message_on_socket(packed_message, socket)
      ensure
        if connection == :writer
          checkin_writer(socket)
        else
          checkin_reader(socket)
        end
      end
    end

    # Sends a message to the database, waits for a response, and raises
    # an exception if the operation has failed.
    #
    # @param [Integer] operation a MongoDB opcode.
    # @param [BSON::ByteBuffer] message a message to send to the database.
    # @param [String] db_name the name of the database. used on call to get_last_error.
    # @param [Hash] last_error_params parameters to be sent to getLastError. See DB#error for
    #   available options.
    #
    # @see DB#get_last_error for valid last error params.
    #
    # @return [Hash] The document returned by the call to getlasterror.
    def send_message_with_safe_check(operation, message, db_name, log_message=nil, last_error_params=false)
      docs = num_received = cursor_id = ''
      add_message_headers(message, operation)

      last_error_message = BSON::ByteBuffer.new
      build_last_error_message(last_error_message, db_name, last_error_params)
      last_error_id = add_message_headers(last_error_message, Mongo::Constants::OP_QUERY)

      packed_message = message.append!(last_error_message).to_s
      begin
        sock = checkout_writer
        @safe_mutexes[sock].synchronize do
          send_message_on_socket(packed_message, sock)
          docs, num_received, cursor_id = receive(sock, last_error_id)
        end
      ensure
        checkin_writer(sock)
      end

      if num_received == 1 && (error = docs[0]['err'] || docs[0]['errmsg'])
        close if error == "not master"
        error = "wtimeout" if error == "timeout"
        raise Mongo::OperationFailure, docs[0]['code'].to_s + ': ' + error
      end

      docs[0]
    end

    # Sends a message to the database and waits for the response.
    #
    # @param [Integer] operation a MongoDB opcode.
    # @param [BSON::ByteBuffer] message a message to send to the database.
    # @param [String] log_message this is currently a no-op and will be removed.
    # @param [Socket] socket a socket to use in lieu of checking out a new one.
    # @param [Boolean] command (false) indicate whether this is a command. If this is a command,
    #   the message will be sent to the primary node.
    #
    # @return [Array]
    #   An array whose indexes include [0] documents returned, [1] number of document received,
    #   and [3] a cursor_id.
    def receive_message(operation, message, log_message=nil, socket=nil, command=false)
      request_id = add_message_headers(message, operation)
      packed_message = message.to_s
      begin
        if socket
          sock = socket
          checkin = false
        else
          sock = (command ? checkout_writer : checkout_reader)
          checkin = true
        end

        result = ''
        @safe_mutexes[sock].synchronize do
          send_message_on_socket(packed_message, sock)
          result = receive(sock, request_id)
        end
      ensure
        if checkin
          command ? checkin_writer(sock) : checkin_reader(sock)
        end
      end
      result
    end

    # Create a new socket and attempt to connect to master.
    # If successful, sets host and port to master and returns the socket.
    #
    # If connecting to a replica set, this method will replace the
    # initially-provided seed list with any nodes known to the set.
    #
    # @raise [ConnectionFailure] if unable to connect to any host or port.
    def connect
      close

      config = check_is_master(@host_to_try)
      if config
        if config['ismaster'] == 1 || config['ismaster'] == true
          @read_primary = true
        elsif @slave_ok
          @read_primary = false
        end

        set_primary(@host_to_try)
      end

      if connected?
        BSON::BSON_CODER.update_max_bson_size(self)
      else
        raise ConnectionFailure, "Failed to connect to a master node at #{@host_to_try[0]}:#{@host_to_try[1]}"
      end
    end
    alias :reconnect :connect

    def connecting?
      @nodes_to_try.length > 0
    end

    # It's possible that we defined connected as all nodes being connected???
    # NOTE: Do check if this needs to be more stringent.
    # Probably not since if any node raises a connection failure, all nodes will be closed.
    def connected?
      @primary_pool && @primary_pool.host && @primary_pool.port
    end

    # Determine if the connection is active. In a normal case the *server_info* operation
    # will be performed without issues, but if the connection was dropped by the server or
    # for some reason the sockets are unsynchronized, a ConnectionFailure will be raised and
    # the return will be false.
    #
    # @return [Boolean]
    def active?
      return false unless connected?

      ping
      true

      rescue ConnectionFailure
      false
    end

    # Determine whether we're reading from a primary node. If false,
    # this connection connects to a secondary node and @slave_ok is true.
    #
    # @return [Boolean]
    def read_primary?
      @read_primary
    end
    alias :primary? :read_primary?

    # Close the connection to the database.
    def close
      @primary_pool.close if @primary_pool
      @primary_pool = nil
      @primary = nil
    end

    # Returns the maximum BSON object size as returned by the core server.
    # Use the 4MB default when the server doesn't report this.
    #
    # @return [Integer]
    def max_bson_size
      config = self['admin'].command({:ismaster => 1})
      config['maxBsonObjectSize'] || Mongo::DEFAULT_MAX_BSON_SIZE
    end

    # Checkout a socket for reading (i.e., a secondary node).
    # Note: this is overridden in ReplSetConnection.
    def checkout_reader
      connect unless connected?
      @primary_pool.checkout
    end

    # Checkout a socket for writing (i.e., a primary node).
    # Note: this is overridden in ReplSetConnection.
    def checkout_writer
      connect unless connected?
      @primary_pool.checkout
    end

    # Checkin a socket used for reading.
    # Note: this is overridden in ReplSetConnection.
    def checkin_reader(socket)
      if @primary_pool
        @primary_pool.checkin(socket)
      end
    end

    # Checkin a socket used for writing.
    # Note: this is overridden in ReplSetConnection.
    def checkin_writer(socket)
      if @primary_pool
        @primary_pool.checkin(socket)
      end
    end

    # Execute the block and log the operation described by name
    # and payload.
    # TODO: Not sure if this should take a block.
    def instrument(name, payload = {}, &blk)
      res = yield
      log_operation(name, payload)
      res
    end

    protected

    # Generic initialization code.
    def setup(opts)
      # Authentication objects
      @auths = opts.fetch(:auths, [])

      # Lock for request ids.
      @id_lock = Mutex.new

      # Pool size and timeout.
      @pool_size = opts[:pool_size] || 1
      @timeout   = opts[:timeout]   || 5.0

      # Timeout on socket read operation.
      @op_timeout = opts[:op_timeout] || nil

      # Mutex for synchronizing pool access
      @connection_mutex = Mutex.new

      # Global safe option. This is false by default.
      @safe = opts[:safe] || false

      # Create a mutex when a new key, in this case a socket,
      # is added to the hash.
      @safe_mutexes = Hash.new { |h, k| h[k] = Mutex.new }

      # Condition variable for signal and wait
      @queue = ConditionVariable.new

      # Connection pool for primay node
      @primary      = nil
      @primary_pool = nil

      @logger = opts[:logger] || nil

      if @logger
        @logger.debug("MongoDB logging. Please note that logging negatively impacts performance " +
        "and should be disabled for high-performance production apps.")
      end

      should_connect = opts.fetch(:connect, true)
      connect if should_connect
    end

    ## Configuration helper methods

    # Returns a host-port pair.
    #
    # @return [Array]
    #
    # @private
    def format_pair(host, port)
      case host
        when String
          [host, port ? port.to_i : DEFAULT_PORT]
        when nil
          ['localhost', DEFAULT_PORT]
      end
    end

    ## Logging methods

    def log_operation(name, payload)
      return unless @logger
      msg = "#{payload[:database]}['#{payload[:collection]}'].#{name}("
      msg += payload.values_at(:selector, :document, :documents, :fields ).compact.map(&:inspect).join(', ') + ")"
      msg += ".skip(#{payload[:skip]})"  if payload[:skip]
      msg += ".limit(#{payload[:limit]})"  if payload[:limit]
      msg += ".sort(#{payload[:order]})"  if payload[:order]
      @logger.debug "MONGODB #{msg}"
    end

    private

    ## Methods for establishing a connection:

    # If a ConnectionFailure is raised, this method will be called
    # to close the connection and reset connection values.
    # TODO: evaluate whether this method is actually necessary
    def reset_connection
      close
    end

    def check_is_master(node)
      begin
        host, port = *node
        socket = TCPSocket.new(host, port)
        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

        config = self['admin'].command({:ismaster => 1}, :socket => socket)
      rescue OperationFailure, SocketError, SystemCallError, IOError => ex
        close
      ensure
        socket.close if socket
      end

      config
    end

    # Set the specified node as primary.
    def set_primary(node)
      host, port = *node
      @primary = [host, port]
      @primary_pool = Pool.new(self, host, port, :size => @pool_size, :timeout => @timeout)
    end

    ## Low-level connection methods.

    def receive(sock, expected_response)
      begin
      receive_header(sock, expected_response)
      number_received, cursor_id = receive_response_header(sock)
      read_documents(number_received, cursor_id, sock)
      rescue Mongo::ConnectionFailure => ex
        close
        raise ex
      end
    end

    def receive_header(sock, expected_response)
      header = receive_message_on_socket(16, sock)
      size, request_id, response_to = header.unpack('VVV')
      if expected_response != response_to
        raise Mongo::ConnectionFailure, "Expected response #{expected_response} but got #{response_to}"
      end

      unless header.size == STANDARD_HEADER_SIZE
        raise "Short read for DB response header: " +
          "expected #{STANDARD_HEADER_SIZE} bytes, saw #{header.size}"
      end
      nil
    end

    def receive_response_header(sock)
      header_buf = receive_message_on_socket(RESPONSE_HEADER_SIZE, sock)
      if header_buf.length != RESPONSE_HEADER_SIZE
        raise "Short read for DB response header; " +
          "expected #{RESPONSE_HEADER_SIZE} bytes, saw #{header_buf.length}"
      end
      flags, cursor_id_a, cursor_id_b, starting_from, number_remaining = header_buf.unpack('VVVVV')
      check_response_flags(flags)
      cursor_id = (cursor_id_b << 32) + cursor_id_a
      [number_remaining, cursor_id]
    end

    def check_response_flags(flags)
      if flags & Mongo::Constants::REPLY_CURSOR_NOT_FOUND != 0
        raise Mongo::OperationFailure, "Query response returned CURSOR_NOT_FOUND. " +
          "Either an invalid cursor was specified, or the cursor may have timed out on the server."
      elsif flags & Mongo::Constants::REPLY_QUERY_FAILURE != 0
        # Getting odd failures when a exception is raised here.
      end
    end

    def read_documents(number_received, cursor_id, sock)
      docs = []
      number_remaining = number_received
      while number_remaining > 0 do
        buf = receive_message_on_socket(4, sock)
        size = buf.unpack('V')[0]
        buf << receive_message_on_socket(size - 4, sock)
        number_remaining -= 1
        docs << BSON::BSON_CODER.deserialize(buf)
      end
      [docs, number_received, cursor_id]
    end

    # Constructs a getlasterror message. This method is used exclusively by
    # Connection#send_message_with_safe_check.
    #
    # Because it modifies message by reference, we don't need to return it.
    def build_last_error_message(message, db_name, opts)
      message.put_int(0)
      BSON::BSON_RUBY.serialize_cstr(message, "#{db_name}.$cmd")
      message.put_int(0)
      message.put_int(-1)
      cmd = BSON::OrderedHash.new
      cmd[:getlasterror] = 1
      if opts.is_a?(Hash)
        opts.assert_valid_keys(:w, :wtimeout, :fsync)
        cmd.merge!(opts)
      end
      message.put_binary(BSON::BSON_CODER.serialize(cmd, false).to_s)
      nil
    end

    # Prepares a message for transmission to MongoDB by
    # constructing a valid message header.
    #
    # Note: this method modifies message by reference.
    #
    # @return [Integer] the request id used in the header
    def add_message_headers(message, operation)
      headers = [
        # Message size.
        16 + message.size,

        # Unique request id.
        request_id = get_request_id,

        # Response id.
        0,

        # Opcode.
        operation
      ].pack('VVVV')

      message.prepend!(headers)

      request_id
    end

    # Increment and return the next available request id.
    #
    # return [Integer]
    def get_request_id
      request_id = ''
      @id_lock.synchronize do
        request_id = @@current_request_id += 1
      end
      request_id
    end

    # Low-level method for sending a message on a socket.
    # Requires a packed message and an available socket,
    #
    # @return [Integer] number of bytes sent
    def send_message_on_socket(packed_message, socket)
      begin
      total_bytes_sent = socket.send(packed_message, 0)
      if total_bytes_sent != packed_message.size
        packed_message.slice!(0, total_bytes_sent)
        while packed_message.size > 0
          byte_sent = socket.send(packed_message, 0)
          total_bytes_sent += byte_sent
          packed_message.slice!(0, byte_sent)
        end
      end
      total_bytes_sent
      rescue => ex
        close
        raise ConnectionFailure, "Operation failed with the following exception: #{ex}"
      end
    end

    # Low-level method for receiving data from socket.
    # Requires length and an available socket.
    def receive_message_on_socket(length, socket)
      begin
        if @op_timeout
          message = nil
          Mongo::TimeoutHandler.timeout(@op_timeout, OperationTimeout) do
            message = receive_data(length, socket)
          end
        else
          message = receive_data(length, socket)
        end
        rescue => ex
          close

          if ex.class == OperationTimeout
            raise OperationTimeout, "Timed out waiting on socket read."
          else
            raise ConnectionFailure, "Operation failed with the following exception: #{ex}"
          end
      end
      message
    end

    def receive_data(length, socket)
      message = new_binary_string
      socket.read(length, message)
      raise ConnectionFailure, "connection closed" unless message && message.length > 0
      if message.length < length
        chunk = new_binary_string
        while message.length < length
          socket.read(length - message.length, chunk)
          raise ConnectionFailure, "connection closed" unless chunk.length > 0
          message << chunk
        end
      end
      message
    end

    if defined?(Encoding)
      BINARY_ENCODING = Encoding.find("binary")

      def new_binary_string
        "".force_encoding(BINARY_ENCODING)
      end
    else
      def new_binary_string
        ""
      end
    end
  end
end
