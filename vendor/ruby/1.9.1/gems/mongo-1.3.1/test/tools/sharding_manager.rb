require 'repl_set_manager'
require 'thread'

class ShardingManager

  attr_accessor :shards

  def initialize(opts={})
    @durable = opts.fetch(:durable, true)
    @host    = "localhost"

    @mongos_port = opts[:mongos_port] || 50000
    @config_port = opts[:config_port] || 40000
    @shard_start_port = opts[:start_shard_port] || 30000
    @path       = File.join(File.expand_path(File.dirname(__FILE__)), "data")
    system("rm -rf #{@path}")

    @shard_count  = 2
    @mongos_count = 1
    @config_count = opts.fetch(:config_count, 1)
    if ![1, 3].include?(@config_count)
      raise ArgumentError, "Must specify 1 or 3 config servers."
    end

    @config_servers = {}
    @mongos_servers = {}
    @shards = []
    @ports  = []
  end

  def kill_random
    shard_to_kill = rand(@shard_count)
    @shards[shard_to_kill].kill_primary
  end

  def restart_killed
    threads = []
    @shards.each do |k, shard|
      threads << Thread.new do
        shard.restart_killed_nodes
      end
    end
  end

  def start_cluster
    start_sharding_components
    start_mongos_servers
    configure_cluster
  end

  def configure_cluster
    add_shards
    enable_sharding
    shard_collection
  end

  def enable_sharding
    mongos['admin'].command({:enablesharding => "app"})
  end

  def shard_collection
    cmd = BSON::OrderedHash.new
    cmd[:shardcollection] = "app.photos"
    cmd[:key] = {:tid => 1}
    p mongos['admin'].command(cmd)
  end

  def add_shards
    @shards.each do |shard|
      cmd = {:addshard => shard.shard_string}
      p cmd
      p mongos['admin'].command(cmd)
    end
    p mongos['admin'].command({:listshards => 1})
  end

  def mongos
    attempt do
      @mongos ||= Mongo::Connection.new(@host, @mongos_servers[0]['port'])
    end
  end

  private

  def start_sharding_components
    system("killall mongos")

    threads = []
    threads << Thread.new do
      start_shards
    end

    threads << Thread.new do
      start_config_servers
    end
    threads.each {|t| t.join}
    puts "\nShards and config servers up!"
  end

  def start_shards
    threads = []
    @shard_count.times do |n|
        threads << Thread.new do
        port = @shard_start_port + n * 100
        shard = ReplSetManager.new(:arbiter_count => 0, :secondary_count => 2,
                       :passive_count => 0, :start_port => port, :durable => @durable,
                       :name => "shard-#{n}")
        shard.start_set
        shard.ensure_up
        @shards << shard
      end
    end
    threads.each {|t| t.join}
  end

  def start_config_servers
    @config_count.times do |n|
      @config_servers[n] ||= {}
      port = @config_port + n
      @ports << port
      @config_servers[n]['port'] = port
      @config_servers[n]['db_path'] = get_path("config-#{port}")
      @config_servers[n]['log_path'] = get_path("log-config-#{port}")
      system("rm -rf #{@config_servers[n]['db_path']}")
      system("mkdir -p #{@config_servers[n]['db_path']}")

      @config_servers[n]['start'] = start_config_cmd(n)

      start(@config_servers, n)
    end
  end

  def start_mongos_servers
    @mongos_count.times do |n|
      @mongos_servers[n] ||= {}
      port = @mongos_port + n
      @ports << port
      @mongos_servers[n]['port'] = port
      @mongos_servers[n]['db_path'] = get_path("mongos-#{port}")
      @mongos_servers[n]['pidfile_path'] = File.join(@mongos_servers[n]['db_path'], "mongod.lock")
      @mongos_servers[n]['log_path'] = get_path("log-mongos-#{port}")
      system("rm -rf #{@mongos_servers[n]['db_path']}")
      system("mkdir -p #{@mongos_servers[n]['db_path']}")

      @mongos_servers[n]['start'] = start_mongos_cmd(n)

      start(@mongos_servers, n)
    end
  end

  def start_config_cmd(n)
    cmd = "mongod --configsvr --logpath '#{@config_servers[n]['log_path']}' " +
     " --dbpath #{@config_servers[n]['db_path']} --port #{@config_servers[n]['port']} --fork"
    cmd += " --dur" if @durable
    cmd
  end

  def start_mongos_cmd(n)
    "mongos --configdb #{config_db_string} --logpath '#{@mongos_servers[n]['log_path']}' " +
      "--pidfilepath #{@mongos_servers[n]['pidfile_path']} --port #{@mongos_servers[n]['port']} --fork"
  end

  def config_db_string
    @config_servers.map do |k, v|
      "#{@host}:#{v['port']}"
    end.join(',')
  end

  def start(set, node)
    system(set[node]['start'])
    set[node]['up'] = true
    sleep(0.5)
    set[node]['pid'] = File.open(File.join(set[node]['db_path'], 'mongod.lock')).read.strip
  end
  alias :restart :start

  private

  def cleanup_config
  end

  def get_path(name)
    File.join(@path, name)
  end

  # TODO: put this into a shared module
  def attempt
    raise "No block given!" unless block_given?
    count = 0

    while count < 50 do
      begin
        return yield
        rescue Mongo::OperationFailure, Mongo::ConnectionFailure
          sleep(1)
          count += 1
      end
    end

    raise exception
  end
end
