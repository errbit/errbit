# encoding: utf-8
require "uri"
require "mongoid/config/database"
require "mongoid/config/replset_database"

module Mongoid #:nodoc

  # This module defines all the configuration options for Mongoid, including the
  # database connections.
  #
  # @todo Durran: This module needs an overhaul, remove singleton, etc.
  module Config
    extend self
    include ActiveModel::Observing

    attr_accessor :master, :settings, :defaults
    @settings = {}
    @defaults = {}

    # Define a configuration option with a default.
    #
    # @example Define the option.
    #   Config.option(:persist_in_safe_mode, :default => false)
    #
    # @param [ Symbol ] name The name of the configuration option.
    # @param [ Hash ] options Extras for the option.
    #
    # @option options [ Object ] :default The default value.
    #
    # @since 2.0.0.rc.1
    def option(name, options = {})
      defaults[name] = settings[name] = options[:default]

      class_eval <<-RUBY
        def #{name}
          settings[#{name.inspect}]
        end

        def #{name}=(value)
          settings[#{name.inspect}] = value
        end

        def #{name}?
          #{name}
        end
      RUBY
    end

    option :allow_dynamic_fields, :default => true
    option :autocreate_indexes, :default => false
    option :identity_map_enabled, :default => false
    option :include_root_in_json, :default => false
    option :max_retries_on_connection_failure, :default => 0
    option :parameterize_keys, :default => true
    option :persist_in_safe_mode, :default => false
    option :preload_models, :default => false
    option :raise_not_found_error, :default => true
    option :skip_version_check, :default => false
    option :time_zone, :default => nil
    option :use_utc, :default => false

    # Adds a new I18n locale file to the load path.
    #
    # @example Add a portuguese locale.
    #   Mongoid::Config.add_language('pt')
    #
    # @example Add all available languages.
    #   Mongoid::Config.add_language('*')
    #
    # @param [ String ] language_code The language to add.
    def add_language(language_code = nil)
      Dir[
        File.join(
          File.dirname(__FILE__), "..", "config", "locales", "#{language_code}.yml"
      )
      ].each do |file|
        I18n.load_path << File.expand_path(file)
      end
    end

    # Get any extra databases that have been configured.
    #
    # @example Get the extras.
    #   config.databases
    #
    # @return [ Hash ] A hash of secondary databases.
    def databases
      configure_extras(@settings["databases"]) unless @databases || !@settings
      @databases || {}
    end

    # @todo Durran: There were no tests around the databases setter, not sure
    # what the exact expectation was. Set with a hash?
    def databases=(databases)
    end

    # Return field names that could cause destructive things to happen if
    # defined in a Mongoid::Document.
    #
    # @example Get the destructive fields.
    #   config.destructive_fields
    #
    # @return [ Array<String> ] An array of bad field names.
    def destructive_fields
      Components.prohibited_methods
    end

    # Configure mongoid from a hash. This is usually called after parsing a
    # yaml config file such as mongoid.yml.
    #
    # @example Configure Mongoid.
    #   config.from_hash({})
    #
    # @param [ Hash ] options The settings to use.
    def from_hash(options = {})
      options.except("database", "slaves", "databases").each_pair do |name, value|
        send("#{name}=", value) if respond_to?("#{name}=")
      end
      @master, @slaves = configure_databases(options)
      configure_extras(options["databases"])
    end

    # Load the settings from a compliant mongoid.yml file. This can be used for
    # easy setup with frameworks other than Rails.
    #
    # @example Configure Mongoid.
    #   Mongoid.load!("/path/to/mongoid.yml")
    #
    # @param [ String ] path The path to the file.
    #
    # @since 2.0.1
    def load!(path)
      environment = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : ENV["RACK_ENV"]
      settings = YAML.load(ERB.new(File.new(path).read).result)[environment]
      if settings.present?
        from_hash(settings)
      end
    end

    # Returns the default logger, which is either a Rails logger of stdout logger
    #
    # @example Get the default logger
    #   config.default_logger
    #
    # @return [ Logger ] The default Logger instance.
    def default_logger
      defined?(Rails) && Rails.respond_to?(:logger) ? Rails.logger : ::Logger.new($stdout)
    end

    # Returns the logger, or defaults to Rails logger or stdout logger.
    #
    # @example Get the logger.
    #   config.logger
    #
    # @return [ Logger ] The configured logger or a default Logger instance.
    def logger
      @logger = default_logger unless defined?(@logger)
      @logger
    end

    # Sets the logger for Mongoid to use.
    #
    # @example Set the logger.
    #   config.logger = Logger.new($stdout, :warn)
    #
    # @return [ Logger ] The newly set logger.
    def logger=(logger)
      case logger
        when Logger then @logger = logger
        when false, nil then @logger = nil
      end
    end

    # Purge all data in all collections, including indexes.
    #
    # @example Purge all data.
    #   Mongoid::Config.purge!
    #
    # @since 2.0.2
    def purge!
      master.collections.map do |collection|
        collection.drop if collection.name !~ /system/
      end
    end

    # Sets whether the times returned from the database use the ruby or
    # the ActiveSupport time zone.
    #
    # @note If you omit this setting, then times will use the ruby time zone.
    #
    # @example Set the time zone config.
    #   Config.use_activesupport_time_zone = true
    #
    # @param [ true, false ] value Whether to use Active Support time zones.
    #
    # @return [ true, false ] The supplied value or false if nil.
    def use_activesupport_time_zone=(value)
      @use_activesupport_time_zone = value || false
    end
    attr_reader :use_activesupport_time_zone
    alias_method :use_activesupport_time_zone?, :use_activesupport_time_zone

    # Sets the Mongo::DB master database to be used. If the object trying to be
    # set is not a valid +Mongo::DB+, then an error will be raised.
    #
    # @example Set the master database.
    #   config.master = Mongo::Connection.new.db("test")
    #
    # @param [ Mongo::DB ] db The master database.
    #
    # @raise [ Errors::InvalidDatabase ] If the master isnt a valid object.
    #
    # @return [ Mongo::DB ] The master instance.
    def master=(db)
      check_database!(db)
      @master = db
    end
    alias :database= :master=

    # Returns the master database, or if none has been set it will raise an
    # error.
    #
    # @example Get the master database.
    #   config.master
    #
    # @raise [ Errors::InvalidDatabase ] If the database was not set.
    #
    # @return [ Mongo::DB ] The master database.
    def master
      unless @master
        @master, @slaves = configure_databases(@settings) unless @settings.blank?
        raise Errors::InvalidDatabase.new(nil) unless @master
      end
      if @reconnect
        @reconnect = false
        reconnect!
      end
      @master
    end
    alias :database :master

    # Convenience method for connecting to the master database after forking a
    # new process.
    #
    # @example Reconnect to the master.
    #   Mongoid.reconnect!
    #
    # @param [ true, false ] now Perform the reconnection immediately?
    def reconnect!(now = true)
      if now
        master.connection.connect
      else
        # We set a @reconnect flag so that #master knows to reconnect the next
        # time the connection is accessed.
        @reconnect = true
      end
    end

    # Reset the configuration options to the defaults.
    #
    # @example Reset the configuration options.
    #   config.reset
    def reset
      settings.replace(defaults)
    end

    # @deprecated User replica sets instead.
    def slaves
      slave_warning!
    end

    # @deprecated User replica sets instead.
    def slaves=(dbs)
      slave_warning!
    end

    protected

    # Check if the database is valid and the correct version.
    #
    # @example Check if the database is valid.
    #   config.check_database!
    #
    # @param [ Mongo::DB ] database The db to check.
    #
    # @raise [ Errors::InvalidDatabase ] If the object is not valid.
    # @raise [ Errors::UnsupportedVersion ] If the db version is too old.
    def check_database!(database)
      raise Errors::InvalidDatabase.new(database) unless database.kind_of?(Mongo::DB)
      unless skip_version_check
        version = database.connection.server_version
        raise Errors::UnsupportedVersion.new(version) if version < Mongoid::MONGODB_VERSION
      end
    end

    # Get a database from settings.
    #
    # @example Configure the master and slave dbs.
    #   config.configure_databases("database" => "mongoid")
    #
    # @param [ Hash ] options The options to use.
    #
    # @option options [ String ] :database The database name.
    # @option options [ String ] :host The database host.
    # @option options [ String ] :password The password for authentication.
    # @option options [ Integer ] :port The port for the database.
    # @option options [ Array<Hash> ] :slaves The slave db options.
    # @option options [ String ] :uri The uri for the database.
    # @option options [ String ] :username The user for authentication.
    #
    # @since 2.0.0.rc.1
    def configure_databases(options)
      if options.has_key?('hosts')
        ReplsetDatabase.new(options).configure
      else
        Database.new(options).configure
      end
    end

    # Get the secondary databases from settings.
    #
    # @example Configure the master and slave dbs.
    #   config.configure_extras("databases" => settings)
    #
    # @param [ Hash ] options The options to use.
    #
    # @since 2.0.0.rc.1
    def configure_extras(extras)
      @databases = (extras || []).inject({}) do |dbs, (name, options)|
        dbs.tap do |extra|
        dbs[name], dbs["#{name}_slaves"] = configure_databases(options)
        end
      end
    end

    # Temporarily here so people can move to replica sets.
    def slave_warning!
      warn(
        "Using Mongoid for traditional slave databases will be removed in the " +
        "next release in preference of replica sets. Please change your setup " +
        "accordingly."
      )
    end
  end
end
