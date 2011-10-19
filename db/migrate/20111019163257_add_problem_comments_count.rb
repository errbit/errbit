class AddProblemCommentsCount < Mongoid::Migration
  def self.up
    Problem.all.each do |problem|
      problem.update_attributes(:comments_count => problem.comments.count)
    end
  end

  def self.down
  end
end