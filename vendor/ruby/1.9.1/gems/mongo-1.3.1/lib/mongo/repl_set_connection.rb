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

module Mongo

  # Instantiates and manages connections to a MongoDB replica set.
  class ReplSetConnection < Connection
    attr_reader :nodes, :secondaries, :arbiters, :read_pool, :secondary_pools

    # Create a connection to a MongoDB replica set.
    #
    # Once connected to a replica set, you can find out which nodes are primary, secondary, and
    # arbiters with the corresponding accessors: Connection#primary, Connection#secondaries, and
    # Connection#arbiters. This is useful if your application needs to connect manually to nodes other
    # than the primary.
    #
    # @param [Array] args A list of host-port pairs to be used as seed nodes followed by a
    #   hash containing any options. See the examples below for exactly how to use the constructor.
    #
    # @option options [String] :rs_name (nil) The name of the replica set to connect to. You
    #   can use this option to verify that you're connecting to the right replica set.
    # @option options [Boolean, Hash] :safe (false) Set the default safe-mode options
    #   propogated to DB objects instantiated off of this Connection. This
    #   default can be overridden upon instantiation of any DB by explicity setting a :safe value
    #   on initialization.
    # @option options [Boolean] :read_secondary(false) If true, a random secondary node will be chosen,
    #   and all reads will be directed to that node.
    # @option options [Logger, #debug] :logger (nil) Logger instance to receive driver operation log.
    # @option options [Integer] :pool_size (1) The maximum number of socket connections allowed per
    #   connection pool. Note: this setting is relevant only for multi-threaded applications.
    # @option options [Float] :timeout (5.0) When all of the connections a pool are checked out,
    #   this is the number of seconds to wait for a new connection to be released before throwing an exception.
    #   Note: this setting is relevant only for multi-threaded applications.
    #
    # @example Connect to a replica set and provide two seed nodes. Note that the number of seed nodes does
    #   not have to be equal to the number of replica set members. The purpose of seed nodes is to permit
    #   the driver to find at least one replica set member even if a member is down.
    #   ReplSetConnection.new(['localhost', 30000], ['localhost', 30001])
    #
    # @example Connect to a replica set providing two seed nodes and ensuring a connection to the replica set named 'prod':
    #   ReplSetConnection.new(['localhost', 30000], ['localhost', 30001], :rs_name => 'prod')
    #
    # @example Connect to a replica set providing two seed nodes and allowing reads from a secondary node:
    #   ReplSetConnection.new(['localhost', 30000], ['localhost', 30001], :read_secondary => true)
    #
    # @see http://api.mongodb.org/ruby/current/file.REPLICA_SETS.html Replica sets in Ruby
    #
    # @raise [ReplicaSetConnectionError] This is raised if a replica set name is specified and the
    #   driver fails to connect to a replica set with that name.
    def initialize(*args)
      if args.last.is_a?(Hash)
        opts = args.pop
      else
        opts = {}
      end

      unless args.length > 0
        raise MongoArgumentError, "A ReplSetConnection requires at least one node."
      end

      # Get seed nodes
      @nodes = args

      # Replica set name
      @replica_set = opts[:rs_name]

      # Cache the various node types when connecting to a replica set.
      @secondaries = []
      @arbiters    = []

      # Connection pools for each secondary node
      @secondary_pools = []
      @read_pool = nil

      # Are we allowing reads from secondaries?
      @read_secondary = opts.fetch(:read_secondary, false)
      @slave_okay = false

      setup(opts)
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
      @nodes_to_try = @nodes.clone

      while connecting?
        node   = @nodes_to_try.shift
        config = check_is_master(node)

        if is_primary?(config)
          set_primary(node)
        else
          set_auxillary(node, config)
        end
      end

      pick_secondary_for_read if @read_secondary

      if connected?
        BSON::BSON_CODER.update_max_bson_size(self)
      else
        if @secondary_pools.empty?
          close # close any existing pools and sockets
          raise ConnectionFailure, "Failed to connect any given host:port"
        else
          close # close any existing pools and sockets
          raise ConnectionFailure, "Failed to connect to primary node."
        end
      end
    end
    alias :reconnect :connect

    def connecting?
      @nodes_to_try.length > 0
    end

    # The replica set primary's host name.
    #
    # @return [String]
    def host
      super
    end

    # The replica set primary's port.
    #
    # @return [Integer]
    def port
      super
    end

    # Determine whether we're reading from a primary node. If false,
    # this connection connects to a secondary node and @read_secondaries is true.
    #
    # @return [Boolean]
    def read_primary?
      !@read_pool
    end
    alias :primary? :read_primary?

    # Close the connection to the database.
    def close
      super
      @read_pool = nil
      @secondary_pools.each do |pool|
        pool.close
      end
      @secondaries     = []
      @secondary_pools = []
      @arbiters        = []
      @nodes_tried  = []
      @nodes_to_try = []
    end

    # If a ConnectionFailure is raised, this method will be called
    # to close the connection and reset connection values.
    # @deprecated
    def reset_connection
      close
      warn "ReplSetConnection#reset_connection is now deprecated. " +
        "Use ReplSetConnection#close instead."
    end

    # Is it okay to connect to a slave?
    #
    # @return [Boolean]
    def slave_ok?
      @read_secondary || @slave_ok
    end

    def authenticate_pools
      super
      @secondary_pools.each do |pool|
        pool.authenticate_existing
      end
    end

    def logout_pools(db)
      super
      @secondary_pools.each do |pool|
        pool.logout_existing(db)
      end
    end

    private

    def check_is_master(node)
      begin
        host, port = *node
        socket = TCPSocket.new(host, port)
        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

        config = self['admin'].command({:ismaster => 1}, :socket => socket)

        check_set_name(config, socket)
      rescue OperationFailure, SocketError, SystemCallError, IOError => ex
        # It's necessary to rescue here. The #connect method will keep trying
        # until it has no more nodes to try and raise a ConnectionFailure if
        # it can't connect to a primary.
      ensure
        socket.close if socket
        @nodes_tried << node

        if config
          nodes = []
          nodes += config['hosts'] if config['hosts']
          nodes += config['arbiters'] if config['arbiters']
          nodes += config['passives'] if config['passives']
          update_node_list(nodes)

          if config['msg'] && @logger
            @logger.warn("MONGODB #{config['msg']}")
          end
        end
      end

      config
    end

    # Primary, when connecting to a replica can, can only be a true primary node.
    # (And not a slave, which is possible when connecting with the standard
    # Connection class.
    def is_primary?(config)
      config && (config['ismaster'] == 1 || config['ismaster'] == true)
    end

    # Pick a node randomly from the set of possible secondaries.
    def pick_secondary_for_read
      if (size = @secondary_pools.size) > 0
        @read_pool = @secondary_pools[rand(size)]
      end
    end

    # Make sure that we're connected to the expected replica set.
    def check_set_name(config, socket)
      if @replica_set
        config = self['admin'].command({:replSetGetStatus => 1},
                   :socket => socket, :check_response => false)

        if !Mongo::Support.ok?(config)
          raise ReplicaSetConnectionError, config['errmsg']
        elsif config['set'] != @replica_set
          raise ReplicaSetConnectionError,
            "Attempting to connect to replica set '#{config['set']}' but expected '#{@replica_set}'"
        end
      end
    end

    # Determines what kind of node we have and caches its host
    # and port so that users can easily connect manually.
    def set_auxillary(node, config)
      if config
        if config['secondary']
          host, port = *node
          @secondaries << node unless @secondaries.include?(node)
          @secondary_pools << Pool.new(self, host, port, :size => @pool_size, :timeout => @timeout)
        elsif config['arbiterOnly']
          @arbiters << node unless @arbiters.include?(node)
        end
      end
    end

    # Update the list of known nodes. Only applies to replica sets,
    # where the response to the ismaster command will return a list
    # of known hosts.
    #
    # @param hosts [Array] a list of hosts, specified as string-encoded
    #   host-port values. Example: ["myserver-1.org:27017", "myserver-1.org:27017"]
    #
    # @return [Array] the updated list of nodes
    def update_node_list(hosts)
      new_nodes = hosts.map do |host|
        if !host.respond_to?(:split)
          warn "Could not parse host #{host.inspect}."
          next
        end

        host, port = host.split(':')
        [host, port ? port.to_i : Connection::DEFAULT_PORT]
      end

      # Replace the list of seed nodes with the canonical list.
      @nodes = new_nodes.clone

      @nodes_to_try = new_nodes - @nodes_tried
    end

    # Checkout a socket for reading (i.e., a secondary node).
    def checkout_reader
      connect unless connected?

      if @read_pool
        @read_pool.checkout
      else
        checkout_writer
      end
    end

    # Checkout a socket for writing (i.e., a primary node).
    def checkout_writer
      connect unless connected?

      @primary_pool.checkout
    end

    # Checkin a socket used for reading.
    def checkin_reader(socket)
      if @read_pool
        @read_pool.checkin(socket)
      else
        checkin_writer(socket)
      end
    end

    # Checkin a socket used for writing.
    def checkin_writer(socket)
      if @primary_pool
        @primary_pool.checkin(socket)
      end
    end
  end
end
