# encoding: utf-8
module Mongoid #:nodoc:
  module Config #:nodoc:

    # This class handles the configuration and initialization of a mongodb
    # database from options.
    class Database < Hash

      # keys to remove from self to not pass through to Mongo::Connection
      PRIVATE_OPTIONS = %w(uri database username password logger)

      # Configure the database connections. This will return an array
      # containing the master and an array of slaves.
      #
      # @example Configure the connection.
      #   db.configure
      #
      # @return [ Array<Mongo::DB, Array<Mongo:DB>> ] The Mongo databases.
      #
      # @since 2.0.0.rc.1
      def configure
        [ master.db(name), slaves.map { |slave| slave.db(name) } ]
      end

      # Create the new db configuration class.
      #
      # @example Initialize the class.
      #   Config::Database.new(
      #     false, "uri" => { "mongodb://durran:password@localhost:27017/mongoid" }
      #   )
      #
      # @param [ Hash ] options The configuration options.
      #
      # @option options [ String ] :database The database name.
      # @option options [ String ] :host The database host.
      # @option options [ String ] :password The password for authentication.
      # @option options [ Integer ] :port The port for the database.
      # @option options [ String ] :uri The uri for the database.
      # @option options [ String ] :username The user for authentication.
      #
      # @since 2.0.0.rc.1
      def initialize(options = {})
        merge!(options)
      end

      private

      # Do we need to authenticate against the database?
      #
      # @example Are we authenticating?
      #   db.authenticating?
      #
      # @return [ true, false ] True if auth is needed, false if not.
      #
      # @since 2.0.0.rc.1
      def authenticating?
        username || password
      end

      # Takes the supplied options in the hash and created a URI from them to
      # pass to the Mongo connection object.
      #
      # @example Build the URI.
      #   db.build_uri
      #
      # @param [ Hash ] options The options to build with.
      #
      # @return [ String ] A mongo compliant URI string.
      #
      # @since 2.0.0.rc.1
      def build_uri(options = {})
        "mongodb://".tap do |base|
          base << "#{username}:#{password}@" if authenticating?
          base << "#{options["host"] || "localhost"}:#{options["port"] || 27017}"
          base << "/#{self["database"]}" if authenticating?
        end
      end

      # Create the mongo master connection from either the supplied URI
      # or a generated one, while setting pool size and logging.
      #
      # @example Create the connection.
      #   db.connection
      #
      # @return [ Mongo::Connection ] The mongo connection.
      #
      # @since 2.0.0.rc.1
      def master
        Mongo::Connection.from_uri(uri(self), optional).tap do |conn|
          conn.apply_saved_authentication
        end
      end

      # Create the mongo slave connections from either the supplied URI
      # or a generated one, while setting pool size and logging.
      #
      # @example Create the connection.
      #   db.connection
      #
      # @return [ Array<Mongo::Connection> ] The mongo slave connections.
      #
      # @since 2.0.0.rc.1
      def slaves
        (self["slaves"] || []).map do |options|
          Mongo::Connection.from_uri(uri(options), optional(true)).tap do |conn|
            conn.apply_saved_authentication
          end
        end
      end

      # Should we use a logger?
      #
      # @example Should we use a logger?
      #   database.logger?
      #
      # @return [ true, false ] Defaults to true, false if specifically
      #   defined.
      #
      # @since 2.2.0
      def logger?
        self[:logger].nil? || self[:logger] ? true : false
      end

      # Convenience for accessing the hash via dot notation.
      #
      # @example Access a value in alternate syntax.
      #   db.host
      #
      # @return [ Object ] The value in the hash.
      #
      # @since 2.0.0.rc.1
      def method_missing(name, *args, &block)
        self[name.to_s]
      end

      # Get the name of the database, from either the URI supplied or the
      # database value in the options.
      #
      # @example Get the database name.
      #   db.name
      #
      # @return [ String ] The database name.
      #
      # @since 2.0.0.rc.1
      def name
        db_name = URI.parse(uri(self)).path.to_s.sub("/", "")
        db_name.blank? ? database : db_name
      end

      # Get the options used in creating the database connection.
      #
      # @example Get the options.
      #   db.options
      #
      # @param [ true, false ] slave Are the options for a slave db?
      #
      # @return [ Hash ] The hash of configuration options.
      #
      # @since 2.0.0.rc.1
      def optional(slave = false)
        ({
          :pool_size => pool_size,
          :logger => logger? ? Mongoid::Logger.new : nil,
          :slave_ok => slave
        }).merge(self).reject { |k,v| PRIVATE_OPTIONS.include? k }.
          inject({}) { |memo, (k, v)| memo[k.to_sym] = v; memo} # mongo likes symbols
      end

      # Get a Mongo compliant URI for the database connection.
      #
      # @example Get the URI.
      #   db.uri
      #
      # @param [ Hash ] options The options hash.
      #
      # @return [ String ] The URI for the connection.
      #
      # @since 2.0.0.rc.1
      def uri(options = {})
        options["uri"] || build_uri(options)
      end
    end
  end
end
