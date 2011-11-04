class CacheProblemStatisticsFix < Mongoid::Migration
  def self.up
    Problem.all.each do |problem|
      messages = {}
      hosts = {}
      user_agents = {}
      problem.notices.each do |notice|
      	messages    = count_attribute(messages, notice.message)
        hosts       = count_attribute(hosts, notice.host)
        user_agents = count_attribute(user_agents, notice.user_agent_string)
      end
      problem.update_attributes(:messages => messages, :hosts => hosts, :user_agents => user_agents)
    end
  end

  def self.down
    Problem.all.each do |problem|
      problem.update_attributes(:messages => {}, :hosts => {}, :user_agents => {})
    end
  end

  private
    def self.count_attribute(counter, value)
      index = Digest::MD5.hexdigest(value.to_s)
      if counter[index].nil?
        counter[index] = {'value' => value, 'count' => 1}
      else
        counter[index]['count'] += 1
      end
  	  counter
  	end

end