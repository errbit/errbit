#!/usr/bin/ruby

require 'thread'

STDOUT.sync = true

unless defined? Mongo
  require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'mongo')
end

class ReplSetManager

  attr_accessor :host, :start_port, :ports, :name, :mongods

  def initialize(opts={})
    @start_port = opts[:start_port] || 30000
    @ports      = []
    @name       = opts[:name] || 'replica-set-foo'
    @host       = opts[:host]  || 'localhost'
    @retries    = opts[:retries] || 60
    @config     = {"_id" => @name, "members" => []}
    @durable    = opts.fetch(:durable, false)
    @path       = File.join(File.expand_path(File.dirname(__FILE__)), "data")

    @arbiter_count   = opts[:arbiter_count]   || 2
    @secondary_count = opts[:secondary_count] || 2
    @passive_count   = opts[:passive_count] || 0
    @primary_count   = 1

    @count = @primary_count + @passive_count + @arbiter_count + @secondary_count
    if @count > 7
      raise StandardError, "Cannot create a replica set with #{node_count} nodes. 7 is the max."
    end

    @mongods   = {}
  end

  def start_set
    puts "** Starting a replica set with #{@count} nodes"

    system("killall mongod")

    n = 0
    (@primary_count + @secondary_count).times do
      init_node(n)
      n += 1
    end

    @passive_count.times do
      init_node(n) do |attrs|
        attrs['priority'] = 0
      end
      n += 1
    end

    @arbiter_count.times do
      init_node(n) do |attrs|
        attrs['arbiterOnly'] = true
      end
      n += 1
    end

    initiate
    ensure_up
  end

  def cleanup_set
    system("killall mongod")
    @count.times do |n|
      system("rm -rf #{@mongods[n]['db_path']}")
    end
  end

  def init_node(n)
    @mongods[n] ||= {}
    port = @start_port + n
    @ports << port
    @mongods[n]['port'] = port
    @mongods[n]['db_path'] = get_path("rs-#{port}")
    @mongods[n]['log_path'] = get_path("log-#{port}")
    system("rm -rf #{@mongods[n]['db_path']}")
    system("mkdir -p #{@mongods[n]['db_path']}")

    @mongods[n]['start'] = start_cmd(n)
    start(n)

    member = {'_id' => n, 'host' => "#{@host}:#{@mongods[n]['port']}"}

    if block_given?
      custom_attrs = {}
      yield custom_attrs
      member.merge!(custom_attrs)
      @mongods[n].merge!(custom_attrs)
    end

    @config['members'] << member
  end

  def start_cmd(n)
    @mongods[n]['start'] = "mongod --replSet #{@name} --logpath '#{@mongods[n]['log_path']}' " +
     " --dbpath #{@mongods[n]['db_path']} --port #{@mongods[n]['port']} --fork"
    @mongods[n]['start'] += " --dur" if @durable
    @mongods[n]['start']
  end

  def kill(node, signal=2)
    pid = @mongods[node]['pid']
    puts "** Killing node with pid #{pid} at port #{@mongods[node]['port']}"
    system("kill -#{signal} #{@mongods[node]['pid']}")
    @mongods[node]['up'] = false
    sleep(1)
  end

  def kill_primary(signal=2)
    node = get_node_with_state(1)
    kill(node, signal)
    return node
  end

  # Note that we have to rescue a connection failure
  # when we run the StepDown command because that
  # command will close the connection.
  def step_down_primary
    primary = get_node_with_state(1)
    con = get_connection(primary)
    begin
      con['admin'].command({'replSetStepDown' => 90})
    rescue Mongo::ConnectionFailure
    end
  end

  def kill_secondary
    node = get_node_with_state(2)
    kill(node)
    return node
  end

  def restart_killed_nodes
    nodes = @mongods.keys.select do |key|
      @mongods[key]['up'] == false
    end

    nodes.each do |node|
      start(node)
    end

    ensure_up
  end

  def get_node_from_port(port)
    @mongods.keys.detect { |key| @mongods[key]['port'] == port }
  end

  def start(node)
    system(@mongods[node]['start'])
    @mongods[node]['up'] = true
    sleep(0.5)
    @mongods[node]['pid'] = File.open(File.join(@mongods[node]['db_path'], 'mongod.lock')).read.strip
  end
  alias :restart :start

  def ensure_up
    print "** Ensuring members are up..."

    attempt do
      con = get_connection
      status = con['admin'].command({'replSetGetStatus' => 1})
      print "."
      if status['members'].all? { |m| m['health'] == 1 && [1, 2, 7].include?(m['state']) } &&
         status['members'].any? { |m| m['state'] == 1 }
        print "all members up!\n\n"
        return status
      else
        raise Mongo::OperationFailure
      end
    end
  end

  def primary
    nodes = get_all_host_pairs_with_state(1)
    nodes.empty? ? nil : nodes[0]
  end

  def secondaries
    get_all_host_pairs_with_state(2)
  end

  def arbiters
    get_all_host_pairs_with_state(7)
  end

  # String used for adding a shard via mongos
  # using the addshard command.
  def shard_string
    str = "#{@name}/"
    str << @mongods.map do |k, mongod|
      "#{@host}:#{mongod['port']}"
    end.join(',')
    str
  end

  private

  def initiate
    con = get_connection

    attempt do
      con['admin'].command({'replSetInitiate' => @config})
    end
  end

  def get_node_with_state(state)
    status = ensure_up
    node = status['members'].detect {|m| m['state'] == state}
    if node
      host_port = node['name'].split(':')
      port = host_port[1] ? host_port[1].to_i : 27017
      key = @mongods.keys.detect {|key| @mongods[key]['port'] == port}
      return key
    else
      return false
    end
  end

  def get_all_host_pairs_with_state(state)
    status = ensure_up
    nodes = status['members'].select {|m| m['state'] == state}
    nodes.map do |node|
      host_port = node['name'].split(':')
      port = host_port[1] ? host_port[1].to_i : 27017
      [host, port]
    end
  end

  def get_connection(node=nil)
    con = attempt do
      if !node
        node = @mongods.keys.detect {|key| !@mongods[key]['arbiterOnly'] && @mongods[key]['up'] }
      end
      con = Mongo::Connection.new(@host, @mongods[node]['port'], :slave_ok => true)
    end

    return con
  end

  def get_path(name)
    File.join(@path, name)
  end

  def attempt
    raise "No block given!" unless block_given?
    count = 0

    while count < @retries do
      begin
        return yield
        rescue Mongo::OperationFailure, Mongo::ConnectionFailure => ex
          sleep(1)
          count += 1
      end
    end

    raise ex
  end

end
