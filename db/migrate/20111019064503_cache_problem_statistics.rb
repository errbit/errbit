class CacheProblemStatistics < Mongoid::Migration
  def self.up
    Problem.all.each do |problem|
      problem.notices.each do |notice|
        problem.messages    << notice.message
        problem.hosts       << notice.host
        problem.user_agents << notice.user_agent_string
      end
      problem.save!
    end
  end

  def self.down
    Problem.all.each do |problem|
      problem.update_attributes(:messages => [], :hosts => [], :user_agents => [])
    end
  end
end