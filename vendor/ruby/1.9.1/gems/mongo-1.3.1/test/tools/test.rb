require 'sharding_manager'

m = ShardingManager.new(:config_count => 3)
m.start_cluster
