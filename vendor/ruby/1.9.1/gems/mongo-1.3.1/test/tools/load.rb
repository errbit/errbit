require 'rubygems'
require 'mongo'
require 'sharding_manager'

class MongoLoader

  def initialize
    @mongo = Mongo::Connection.new("localhost", 50000)
    @data  = BSON::Binary.new(File.open("tools.gz").read)
    @count = 0
    @manager = ShardingManager.new(:config_count => 3)
    @manager.start_cluster
  end

  def kill
    @manager.kill_random
  end

  def restart
    @manager.restart_killed_nodes
  end

  def run
    Thread.new do
      ("a".."z").each do |p|
        seed(p)
      end
    end
  end

  def seed(prefix)
    @queue = []
    1000.times do |n|
      id = BSON::OrderedHash.new
      id[:p] = prefix
      id[:c] = n
      @queue << {:tid => id, :data => @data}
    end

    while @queue.length > 0 do
      begin
        doc = @queue.pop
        @mongo['app']['photos'].insert(doc, :safe => {:w => 3})
        @count += 1
        p @count
        rescue StandardError => e
          p e
          p @count
          @queue.push(doc)
          @count -= 1
          sleep(10)
          retry
      end
    end
  end
end

@m = MongoLoader.new
